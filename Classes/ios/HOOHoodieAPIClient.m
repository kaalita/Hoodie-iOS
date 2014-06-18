//
//  HOOHoodieAPIClient.m
//  Pods
//
//  Created by Katrin Apel on 31/05/14.
//
//

#import "HOOHoodieAPIClient.h"
#import "AFNetworking.h"
#import "HOOHoodie.h"
#import <CouchbaseLite/CouchbaseLite.h>
#import "HOOErrorGenerator.h"

@interface HOOHoodieAPIClient ()

@property (nonatomic, strong) HOOHoodie *hoodie;
@property (nonatomic, strong) AFHTTPRequestOperationManager *requestManager;
@property (nonatomic, strong) NSURLProtectionSpace *remoteDatabaseProtectionSpace;

@end

@implementation HOOHoodieAPIClient

-(id) initWithBaseURLString:(NSString *)baseURLString hoodie:(HOOHoodie *)hoodie
{
    self = [super init];
    if(self)
    {
        self.hoodie = hoodie;
        
        NSURL *url = [NSURL URLWithString: [self removeTrailingSlashFromURLString:baseURLString]];
        self.apiURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/_api",url]];
        
        [self setupRequestManager];
        
        self.remoteDatabaseProtectionSpace = [[NSURLProtectionSpace alloc] initWithHost:self.apiURL.host
                                                                                   port:[self.apiURL.port integerValue]
                                                                               protocol:self.apiURL.scheme
                                                                                  realm:nil
                                                                   authenticationMethod:NSURLAuthenticationMethodHTTPDigest];
    }
    
    return self;
}

#pragma mark - Hoodie API

-(void)createAccountWithUsername:username
                        password:password
                        onFinished:(void (^)(NSString *username, NSError * error))onFinished;
{
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
    NSString *pathToUser = [NSString stringWithFormat:@"%@/_users/%@", self.apiURL, escapedUserID];
    
    [self.requestManager PUT:pathToUser
                  parameters:userDictionary
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         
                         NSString *couchUserID = responseObject[@"id"];
                         NSString *returnedUsername = [couchUserID componentsSeparatedByString:@"/"][1];
                         onFinished(returnedUsername, nil);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         
                         // A conflict means that the username already exists
                         if([operation.response statusCode] == 409)
                         {
                             onFinished(username, [HOOErrorGenerator errorWithType:HOOAccountSignUpUsernameTakenError]);
                         }
                         else
                         {
                             onFinished(username, error);
                         }
                     }
     ];
}

- (void)signInUserWithName:(NSString *)username
                  password:(NSString *)password
                  onSignIn:(void (^)(NSString *hoodieID, NSError *error))onSignInFinished;
{
    NSDictionary * requestOptions = @{
                                      @"name": [self hoodiePrefixUsername:username],
                                      @"password": password
                                      };
    
    [self.requestManager POST:[NSString stringWithFormat:@"%@/_session", self.apiURL]
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
                              NSString *returnedHoodieID = roles[0];
                              onSignInFinished(returnedHoodieID,nil);
                              
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
    [self.requestManager DELETE:[NSString stringWithFormat:@"%@/_session", self.apiURL]
                     parameters:@{}
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            
                            onSignOutFinished(YES,nil);
                        }
                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            
                            NSLog(@"HOODIE - Sign out failed: %@", [error localizedDescription]);
                            onSignOutFinished(NO, error);
                        }];
}

-(void)setNewPassword:(NSString *)newPassword
          forUsername:(NSString *)username
     onPasswordChange:(void (^)(BOOL passwordChangeSuccessful, NSError * error))onPasswordChangeFinished
{

    [self fetchDocumentForUsername:username OnFinished:^(NSDictionary *userDocument, NSError *error) {
       
        if(userDocument)
        {
            NSString *prefixedUsername = [NSString stringWithFormat:@"user/%@",[username lowercaseString]];
            NSString *userID = [NSString stringWithFormat:@"org.couchdb.user:%@",prefixedUsername];
            
            NSMutableDictionary *newUserDocument = [[NSMutableDictionary alloc] initWithDictionary:userDocument];
            
            newUserDocument[@"password"] = newPassword;
            newUserDocument[@"updatedAt"] = [CBLJSON JSONObjectWithDate: [NSDate new]];
            [newUserDocument removeObjectsForKeys:@[@"salt", @"password_sha"]];
            
            NSString *escapedUserID = [userID stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
            NSString *pathToUser = [NSString stringWithFormat:@"%@/_users/%@", self.apiURL, escapedUserID];
            
            [self.requestManager PUT:pathToUser
                          parameters:newUserDocument
                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 
                                 onPasswordChangeFinished(YES,nil);
                             }
                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                 
                                 onPasswordChangeFinished(NO, error);
                             }
             ];
        }
        else
        {
            onPasswordChangeFinished(NO, error);
        }
    }];
}

-(void)setNewPassword:(NSString *)newPassword
          newUsername:(NSString *)newUsername
          forUsername:(NSString *)username
     onChangeFinished:(void (^)(BOOL, NSError *))onChangeFinished
{
    [self fetchDocumentForUsername:username OnFinished:^(NSDictionary *userDocument, NSError *error) {
        
        if(userDocument)
        {
            NSString *prefixedUsername = [NSString stringWithFormat:@"user/%@",[username lowercaseString]];
            NSString *userID = [NSString stringWithFormat:@"org.couchdb.user:%@",prefixedUsername];
            
            NSMutableDictionary *newUserDocument = [[NSMutableDictionary alloc] initWithDictionary:userDocument];
            
            newUserDocument[@"$newUsername"] = newUsername;
            newUserDocument[@"password"] = newPassword;
            newUserDocument[@"updatedAt"] = [CBLJSON JSONObjectWithDate: [NSDate new]];
            [newUserDocument removeObjectsForKeys:@[@"salt", @"password_sha"]];
            
            NSString *escapedUserID = [userID stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
            NSString *pathToUser = [NSString stringWithFormat:@"%@/_users/%@", self.apiURL, escapedUserID];
            
            [self.requestManager PUT:pathToUser
                          parameters:newUserDocument
                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 
                                 onChangeFinished(YES, nil);
                             }
                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                 
                                 onChangeFinished(NO, error);
                             }
             ];
        }
        else
        {
            onChangeFinished(NO,error);
        }
    }];
}

-(NSURL *)remoteStoreURLForUsername:(NSString *)username
{
    NSString *userDatabaseNameURLEncoded = [[self userDatabaseName] stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *userDatabaseURLString = [NSString stringWithFormat:@"%@/%@",self.apiURL,userDatabaseNameURLEncoded];
    
    return [NSURL URLWithString:userDatabaseURLString];
}

#pragma mark - Credential

- (NSURLCredential *)credential
{
    NSURLCredential *credential;
    NSDictionary *credentials;
    
    credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:self.remoteDatabaseProtectionSpace];
    credential = [credentials.objectEnumerator nextObject];
    return credential;   
}

-(void)setCredentialUsername:(NSString *)username password:(NSString *)password
{
    NSURLCredential *accountCredentials;
    accountCredentials = [NSURLCredential credentialWithUser:username
                                                    password:password
                                                 persistence:NSURLCredentialPersistencePermanent];
    
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:accountCredentials
                                                 forProtectionSpace:self.remoteDatabaseProtectionSpace];
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

#pragma mark - Helper methods

-(void)setupRequestManager
{
    self.requestManager = [AFHTTPRequestOperationManager manager];
    self.requestManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Set Accept Header, otherwise CouchDB sends JSON response with content type text/plain
    // See http://guide.couchdb.org/draft/api.html
    [self.requestManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (NSString *)hoodiePrefixUsername:(NSString *)username
{
    return [NSString stringWithFormat:@"user/%@",username];
}

- (NSString *)userDatabaseName
{
    return  [NSString stringWithFormat:@"user/%@",self.hoodie.hoodieID];
}

- (void)fetchDocumentForUsername:(NSString *)username
                      OnFinished:(void (^)(NSDictionary *userDocument, NSError *error))onFinished
{
    NSString *prefixedUsername = [NSString stringWithFormat:@"user/%@",[username lowercaseString]];
    NSString *userID = [NSString stringWithFormat:@"org.couchdb.user:%@",prefixedUsername];
    NSString *escapedUserID = [userID stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    NSString *pathToUser = [NSString stringWithFormat:@"%@/_users/%@", self.apiURL, escapedUserID];
    
    [self.requestManager GET:pathToUser
                  parameters:nil
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         
                         onFinished(operation.responseObject,nil);
                         
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         
                         onFinished(nil, error);
                     }];
}

- (NSString *)removeTrailingSlashFromURLString: (NSString *) urlString
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/+$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:urlString
                                                               options:0
                                                                 range:NSMakeRange(0, [urlString length])
                                                          withTemplate:@""];
    return modifiedString;
}

@end
