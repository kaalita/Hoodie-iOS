//
//  HOOHoodieAPIClient.h
//  Pods
//
//  Created by Katrin Apel on 31/05/14.
//
//

#import <Foundation/Foundation.h>

@class HOOHoodie;

@interface HOOHoodieAPIClient : NSObject

@property (nonatomic, strong) NSURL *apiURL;
@property (nonatomic, readonly) NSURLCredential *credential;

- (id)initWithBaseURLString:(NSString *)baseURLString
                     hoodie:(HOOHoodie *)hoodie;

-(void)setCredentialUsername:(NSString *)username
                    password:(NSString *)password;

-(void)clearCredentials;

-(NSURL *)remoteStoreURLForUsername:(NSString *)username;

-(void)createAccountWithUsername:username
                        password:password
                      onFinished:(void (^)(NSString *username, NSError * error))onFinished;


-(void)signInUserWithName:(NSString *)username
                password:(NSString *)password
                onSignIn:(void (^)(NSString* hoodieID, NSError *error))onSignInFinished;

-(void)signOutOnFinished:(void (^)(BOOL signOutSuccessful, NSError *error))onSignOutFinished;

-(void)setNewPassword:(NSString *)newPassword
          forUsername:(NSString *)username
     onPasswordChange:(void (^)(BOOL passwordChangeSuccessful, NSError * error))onPasswordChangeFinished;

-(void)setNewPassword:(NSString *)newPassword
          newUsername:(NSString *)newUsername
          forUsername:(NSString *)username
     onChangeFinished:(void (^)(BOOL changeSuccessful, NSError * error))onChangeFinished;


@end
