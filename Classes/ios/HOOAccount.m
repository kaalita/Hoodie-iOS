//
// Created by Katrin Apel on 03/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOAccount.h"
#import "AFNetworking.h"
#import "CouchbaseLite.h"
#import "HOOHoodie.h"
#import "HOOErrorGenerator.h"
#import "HOOHelper.h"

@interface HOOAccount ()

@property (nonatomic, strong) AFHTTPRequestOperationManager *requestManager;
@property (nonatomic, strong) NSURLProtectionSpace *remoteDatabaseProtectionSpace;
@property (nonatomic, strong) HOOHoodie *hoodie;
@property(nonatomic, assign, readwrite) BOOL authenticated;

@end

@implementation HOOAccount

- (id)initWithHoodie:(HOOHoodie *)hoodie
{
    self = [super init];
    if(self)
    {
        self.hoodie = hoodie;

        self.remoteDatabaseProtectionSpace = [[NSURLProtectionSpace alloc] initWithHost:self.hoodie.baseURL.host
                                                                                   port:[self.hoodie.baseURL.port integerValue]
                                                                               protocol:self.hoodie.baseURL.scheme
                                                                                  realm:nil
                                                                   authenticationMethod:NSURLAuthenticationMethodHTTPDigest];

        self.requestManager = [AFHTTPRequestOperationManager manager];
        self.requestManager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.requestManager.responseSerializer = [AFJSONResponseSerializer serializer];

        // Set Accept Header, otherwise CouchDB sends JSON response with content type text/plain
        // See http://guide.couchdb.org/draft/api.html
        [self.requestManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }

    return self;
}

- (void)automaticallySignInExistingUser:(void (^)(BOOL existingUser, NSError *error))onFinished
{
   NSURLCredentialStorage *credentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
   NSURLCredential *userCredentials =  [credentialStorage defaultCredentialForProtectionSpace:self.remoteDatabaseProtectionSpace];

   if(userCredentials)
   {
       self.username  = userCredentials.user;
       [self setAccountDatabase];
       [self signInUserWithName:userCredentials.user
                       password:userCredentials.password
                       onSignIn:^(BOOL signInSuccessful, NSError *error) {
                            onFinished(YES, error);
                       }];
   }
    else
   {
        onFinished(NO, nil);
   }
}

- (void)signUpUserWithName:(NSString *)username
                  password:(NSString *)password
                  onSignUp:(void (^)(BOOL signUpSuccessful, NSError *error))onSignUpFinished
{
    if(!username || [username isEqualToString:@""])
    {
        onSignUpFinished(NO, [HOOErrorGenerator errorWithType:HOOAccountSignUpUsernameEmptyError]);
        return;
    }

    if(!password)
    {
        password = @"";
    }

    NSString *prefixedUsername = [NSString stringWithFormat:@"user/%@",[username lowercaseString]];
    NSString *userID = [NSString stringWithFormat:@"org.couchdb.user:%@",prefixedUsername];

    NSDictionary *userDictionary = @{
            @"_id": userID,
            @"type": @"user",
            @"name": prefixedUsername,
            @"database": [self userDatabaseName],
            @"roles": @[],
            @"password": password,
            @"hoodieId": self.hoodie.hoodieID,
            @"updatedAt": [CBLJSON JSONObjectWithDate: [NSDate new]],
            @"createdAt": [CBLJSON JSONObjectWithDate: [NSDate new]],
            @"signedUpAt": [CBLJSON JSONObjectWithDate: [NSDate new]]
    };

    NSString *escapedUserID = [userID stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *pathToUser = [NSString stringWithFormat:@"%@/_users/%@", self.hoodie.baseURL, escapedUserID];

    [self.requestManager PUT:pathToUser
                  parameters:userDictionary
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {

                         // Sign in user after sign up
                         [self delayedSignInWithUsername:username
                                                password:password
                                         numberOfRetries:10
                                         onDelayedSignIn:^(BOOL signInSuccessful, NSError *error) {

                                             [self setAccountDatabase];
                                             onSignUpFinished(YES, nil);
                         }];
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                        // A conflict means that the username already exists
                        if([operation.response statusCode] == 409)
                        {
                            onSignUpFinished(NO, [HOOErrorGenerator errorWithType:HOOAccountSignUpUsernameTakenError]);
                        }
                        else
                        {
                            onSignUpFinished(NO, error);
                        }
                    }
    ];
}

- (void)signInUserWithName:(NSString *)username
                  password:(NSString *)password
                  onSignIn:(void (^)(BOOL signInSuccessful, NSError *error))onSignInFinished
{
    NSDictionary * requestOptions = @{
            @"name": [self hoodiePrefixUsername:username],
            @"password": password
    };

    [self.requestManager POST:[NSString stringWithFormat:@"%@/_session", self.hoodie.baseURL]
                   parameters:requestOptions

                      success:^(AFHTTPRequestOperation *operation, id responseObject) {

                          NSArray *roles = [responseObject valueForKey:@"roles"];
                          NSUInteger indexOfConfirmedRole = [roles indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                                      return [obj isEqualToString:@"confirmed"];
                          }];
                          if(indexOfConfirmedRole == NSNotFound)
                          {
                              onSignInFinished(NO, [HOOErrorGenerator errorWithType:HOOAccountUnconfirmedError]);
                          }
                          else
                          {
                              NSURLCredential *accountCredentials;
                              accountCredentials = [NSURLCredential credentialWithUser:username
                                                                     password:password
                                                                  persistence:NSURLCredentialPersistencePermanent];

                              [[NSURLCredentialStorage sharedCredentialStorage] setCredential:accountCredentials
                                                                           forProtectionSpace:self.remoteDatabaseProtectionSpace];

                              self.hoodie.hoodieID = roles[0];
                              self.username = username;

                              [self setAccountDatabase];

                              self.authenticated = YES;
                              onSignInFinished(YES, nil);
                          }
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                          if([operation.response statusCode] == 401)
                          {
                              onSignInFinished(NO, [HOOErrorGenerator errorWithType:HOOAccountSignInWrongCredentialsError]);
                          }
                          else
                          {
                              onSignInFinished(NO, error);
                          }
                      }
    ];
}

- (void)signOutOnFinished:(void (^)(BOOL signOutSuccessful, NSError *error))onSignOutFinished
{
    [self.requestManager DELETE:[NSString stringWithFormat:@"%@/_session", self.hoodie.baseURL]
                     parameters:@{}
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {

                            [self.hoodie.store clearLocalData];
                            [self clearCredentials];
                            self.hoodie.hoodieID = [HOOHelper generateHoodieID];
                            self.authenticated = NO;
                            onSignOutFinished(YES, nil);

                        }
                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                            NSLog(@"HOODIE - Sign out failed: %@", [error localizedDescription]);
                            onSignOutFinished(NO, error);
                        }];
}

- (void)clearCredentials
{
    NSURLCredential *credential;
    NSDictionary *credentials;

    credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:self.remoteDatabaseProtectionSpace];
    credential = [credentials.objectEnumerator nextObject];
    [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential
                                                    forProtectionSpace:self.remoteDatabaseProtectionSpace];

}

- (void)delayedSignInWithArguments: (NSArray *) arguments
{
    if(arguments.count == 4)
    {
        [self delayedSignInWithUsername:arguments[0]
                               password:arguments[1]
                        numberOfRetries:((NSNumber *) arguments[2]).unsignedIntegerValue
                        onDelayedSignIn:arguments[3]];

    }
}

- (void)delayedSignInWithUsername:(NSString *)username
                         password:(NSString *)password
                  numberOfRetries:(NSUInteger)numberOfRetries
                  onDelayedSignIn:(void (^)(BOOL signInSuccessful, NSError *error))onDelayedSignInFinished
{
    if(numberOfRetries > 0)
    {
        numberOfRetries = numberOfRetries - 1;

        [self signInUserWithName:username
                        password:password
                        onSignIn:^(BOOL signInSuccessful, NSError *error) {
                            if(signInSuccessful)
                            {
                                onDelayedSignInFinished(YES, nil);
                            }
                            else
                            {
                                if(error.code == HOOAccountUnconfirmedError)
                                {
                                    [self performSelector:@selector(delayedSignInWithArguments:)
                                               withObject:@[username, password,@(numberOfRetries),onDelayedSignInFinished]
                                               afterDelay:0.3];
                                }
                            }
                        }];
    }
    else
    {
        NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: NSLocalizedString(@"Sign in failed", nil),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Couldn't sign in user.", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please try to sign in again later.", nil)
        };
        NSError *error = [NSError errorWithDomain:@"hoodie.signup"
                                             code:1
                                         userInfo:userInfo];
        onDelayedSignInFinished(NO,error);
    }
}

#pragma mark - Helper methods

- (NSString *)hoodiePrefixUsername:(NSString *)username
{
    return [NSString stringWithFormat:@"user/%@",username];
}

- (NSString *)userDatabaseName
{
    return  [NSString stringWithFormat:@"user/%@",self.hoodie.hoodieID];
}

- (void)setAccountDatabase
{
    NSString *userDatabaseNameURLEncoded = [[self userDatabaseName] stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *userDatabaseURL = [NSString stringWithFormat:@"%@/%@",self.hoodie.baseURL,userDatabaseNameURLEncoded];
    self.hoodie.store.remoteStoreURL = [NSURL URLWithString:userDatabaseURL];
}

@end