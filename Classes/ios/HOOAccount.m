//
// Created by Katrin Apel on 03/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOAccount.h"
#import "HOOHoodie.h"
#import "HOOHoodieAPIClient.h"
#import "HOOErrorGenerator.h"
#import "HOOHelper.h"

@interface HOOAccount ()

@property (nonatomic, strong) HOOHoodie *hoodie;
@property (nonatomic, assign, readwrite) BOOL authenticated;

@end

@implementation HOOAccount

- (id)initWithHoodie:(HOOHoodie *)hoodie
{
    self = [super init];
    if(self)
    {
        self.hoodie = hoodie;
    }

    return self;
}

- (void)automaticallySignInExistingUser:(void (^)(BOOL existingUser, NSError *error))onFinished
{
    NSURLCredential *userCredentials = self.hoodie.apiClient.credential;

   if(userCredentials)
   {
       self.username  = userCredentials.user;
       [self.hoodie.store setAccountDatabaseForUsername:self.username];
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

- (void)anonymousSignUpOnFinished:(void (^)(BOOL signUpSuccessful, NSError *error))onSignUpFinished
{
    NSString *username = self.hoodie.hoodieID;
    NSString *generatedPassword = [HOOHelper generateHoodieID];
    
    [self signUpUserWithName:username
                    password:generatedPassword
                    onSignUp:^(BOOL signUpSuccessful, NSError *error) {
       
        onSignUpFinished(signUpSuccessful,error);
    }];
}

- (BOOL)hasAnonymousAccount
{
    if([self.username isEqualToString:self.hoodie.hoodieID])
    {
        return YES;
    }
    else
    {
        return NO;
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
    
    if([self hasAnonymousAccount])
    {
        [self upgradeAnonymousAccountWithUsername:username
                                         password:password
                                onUpgradeFinished:^(BOOL upgradeSuccessful, NSError *error) {
                                    
                                    onSignUpFinished(upgradeSuccessful,error);
                                    return;
                                }
         ];
    }
    else
    {
        [self createNewAccountWithUsername:username
                                  password:password
                                onFinished:^(BOOL accountCreationSuccessul, NSError *error)
         {
             onSignUpFinished(accountCreationSuccessul,error);
             return;
         }];
    }
}

- (void)signInUserWithName:(NSString *)username
                  password:(NSString *)password
                  onSignIn:(void (^)(BOOL signInSuccessful, NSError *error))onSignInFinished
{
    [self.hoodie.apiClient signInUserWithName:username
                                     password:password
                                     onSignIn:^(NSString *hoodieID, NSError *error) {
       
                                         if(!error)
                                         {
                                             [self.hoodie.apiClient setCredentialUsername:username
                                                                                 password:password];
                                             self.hoodie.hoodieID = hoodieID;
                                             self.username = username;
                                             
                                             [self.hoodie.store setAccountDatabaseForUsername:username];
                                             
                                             self.authenticated = YES;
                                             onSignInFinished(YES, nil);

                                         }
                                         else
                                         {
                                             onSignInFinished(NO,error);
                                         }
                                         
    }];
}

- (void)signOutOnFinished:(void (^)(BOOL signOutSuccessful, NSError *error))onSignOutFinished
{
    [self.hoodie.apiClient signOutOnFinished:^(BOOL signOutSuccessful, NSError *error) {
       
        [self.hoodie.store clearLocalData];
        [self.hoodie.apiClient clearCredentials];
        self.hoodie.hoodieID = [HOOHelper generateHoodieID];
        self.authenticated = NO;
        
        onSignOutFinished(YES, error);
    }];
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

- (void)changeOldPassword: (NSString *) oldPassword
            toNewPassword: (NSString *) newPassword
         onPasswordChange: (void (^)(BOOL passwordChangeSuccessful, NSError * error))onPasswordChangeFinished
{
 
    if(!newPassword)
    {
        newPassword = @"";
    }
    
    [self.hoodie.apiClient setNewPassword:newPassword
                              forUsername:self.username
                         onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                             
                             if(passwordChangeSuccessful)
                             {
                                 [self signInUserWithName:self.username
                                                 password:newPassword
                                                 onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                                     
                                                     if(signInSuccessful)
                                                     {
                                                         onPasswordChangeFinished(YES,nil);
                                                     }
                                                     else
                                                     {
                                                         onPasswordChangeFinished(NO,error);
                                                     }
                                                 }];
                             }
                             else
                             {
                                 onPasswordChangeFinished(NO,error);
                             }
    }];
}


#pragma mark - Helper methods

- (void)changeUsername:(NSString *)newUsername
           andPassword:(NSString *)newPassword
   withCurrentPassword:(NSString *)currentPassword
      onChangeFinished:(void (^)(BOOL changeSuccessful, NSError * error))onChangeFinished
{
        [self.hoodie.apiClient setNewPassword:newPassword
                                  newUsername:newUsername
                                  forUsername:self.username onChangeFinished:^(BOOL changeSuccessful, NSError *error) {
                                      
                                      if(changeSuccessful)
                                      {
                                          self.username = newUsername;
                                      }
                                      onChangeFinished(changeSuccessful,error);
        }];
}

- (void)upgradeAnonymousAccountWithUsername:(NSString *)username
                                   password:(NSString *)password
                          onUpgradeFinished:(void (^)(BOOL upgradeSuccessful, NSError * error))onUpgradeFinished
{
    
    NSString *currentPassword = self.hoodie.apiClient.credential.password;
    
    [self changeUsername:username
             andPassword:password
     withCurrentPassword:currentPassword
        onChangeFinished:^(BOOL changeSuccessful, NSError *error) {
         
            onUpgradeFinished(changeSuccessful, error);
    }];
}

-(void)createNewAccountWithUsername:username
                           password:password
                         onFinished:(void (^)(BOOL accountCreationSuccessful, NSError * error))onFinished
{
    [self.hoodie.apiClient createAccountWithUsername:username
                                            password:password
                                          onFinished:^(NSString *username, NSError *error) {
                                              
                                              if(!error)
                                              {
                                                  [self delayedSignInWithUsername:username
                                                                         password:password
                                                                  numberOfRetries:10
                                                                  onDelayedSignIn:^(BOOL signInSuccessful, NSError *error) {
                                                                      
                                                                      onFinished(YES, nil);
                                                                  }];
                                              }
                                              else
                                              {
                                                  onFinished(NO,error);
                                              }
         
     }];
}

@end