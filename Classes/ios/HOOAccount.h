//
// Created by Katrin Apel on 03/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HOOHoodie;

@interface HOOAccount : NSObject

@property(nonatomic, assign, readonly) BOOL authenticated;
@property(nonatomic, strong) NSString *username;

- (id)initWithHoodie:(HOOHoodie *)hoodie;


- (void)automaticallySignInExistingUser:(void (^)(BOOL existingUser, NSError *error))onFinished;


- (void)signUpUserWithName: (NSString *) username
                  password: (NSString *) password
                  onSignUp: (void (^)(BOOL signUpSuccessful, NSError * error))onSignUpFinished;


- (void)signInUserWithName: (NSString *) username
                  password: (NSString *) password
                  onSignIn: (void (^)(BOOL signInSuccessful, NSError * error))onSignInFinished;


- (void)signOutOnFinished:(void (^)(BOOL signOutSuccessful, NSError *error))onSignOutFinished;


- (void)changeOldPassword: (NSString *) oldPassword
            toNewPassword: (NSString *) newPassword
         onPasswordChange: (void (^)(BOOL passwordChangeSuccessful, NSError * error))onPasswordChangeFinished;

@end