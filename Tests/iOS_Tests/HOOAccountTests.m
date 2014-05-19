//
//  HOOAccountTests.m
//  iOS_Tests
//
//  Created by Katrin Apel on 24/03/14.
//
//

#import "Kiwi.h"
#import "HOOHoodie.h"
#import "HOOErrorGenerator.h"
#import "FakeHoodieServer.h"

SPEC_BEGIN(HOOAccountSpec)

describe(@"HOOAccount", ^{
    
    NSString *host = @"http://localhost.:6001";
    NSString *baseURL = [NSString stringWithFormat:@"%@/_api",host];
    
    HOOHoodie *hoodie = [HOOHoodie mock];
    [hoodie stub:@selector(baseURL) andReturn: [NSURL URLWithString: baseURL]];
    [hoodie stub:@selector(hoodieID) andReturn:@"uuid123"];
    [hoodie stub:@selector(setHoodieID:)];
    
    HOOStore *store = [HOOStore mock];
    [store stub:@selector(setRemoteStoreURL:)];
    [hoodie stub:@selector(store) andReturn:store];
    
    FakeHoodieServer *hoodieServer = [[FakeHoodieServer alloc] initWithSignUpResponseType:HOOSignUpResponseTypeSuccess
                                                                       signInResponseType:HOOSignInResponseTypeSuccessConfirmedUser
                                                                      getUserResponseType:HOOGetUserResponseTypeSuccessConfirmedUser];
    __block HOOAccount *account;
    
    beforeEach(^{
        account = [[HOOAccount alloc] initWithHoodie:hoodie];
    });
    
#pragma mark - Sign up

    context(@"signup with username and password", ^{
        
        it(@"should be rejected if username not set", ^{
            
            __block BOOL _signUpSuccessful;
            __block NSError *_error = nil;
           
            [account signUpUserWithName:@""
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                                   
                                   _signUpSuccessful = signUpSuccessful;
                                   _error = error;
            }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] beFalse];
            [[expectFutureValue(@(_error.code)) shouldEventually] equal:@(HOOAccountSignUpUsernameEmptyError)];
        });

        it(@"should lowercase the username", ^{
            
            [account signUpUserWithName:@"JOE"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                               }];
            
            [[expectFutureValue(account.username) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:@"joe"];
        });
    });

    context(@"signup successful", ^{
        
        it(@"should sign in user", ^{
            
            [account signUpUserWithName:@"joe"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                               }];
            
            [[[account shouldEventuallyBeforeTimingOutAfter(2.0)] receive] signInUserWithName:@"joe"
                                                                                     password:@"secret"
                                                                                     onSignIn:any()];
        });
    });
    
    context(@"signup has a conflict error", ^{
        
        it(@"should reject signup and return a username already taken error", ^{
            
            hoodieServer.signUpResponseType = HOOSignUpResponseTypeErrorUsernameTaken;
            
            __block NSError *_signUpError;
            __block BOOL _signUpSuccessful;
            
            [account signUpUserWithName:@"exists@example.com"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                                   
                                   _signUpSuccessful = signUpSuccessful;
                                   _signUpError = error;
                               }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventuallyBeforeTimingOutAfter(2.0)] beFalse];
            [[expectFutureValue(@(_signUpError.code)) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:@(HOOAccountSignUpUsernameTakenError)];
        });
    });
    
    
#pragma mark - Sign in
    
    context(@"sign in successful and account is confirmed", ^{
        
        it(@"should call onSignIn(YES, nil)", ^{

            hoodieServer.signInResponseType = HOOSignInResponseTypeSuccessConfirmedUser;
            
            __block BOOL _signInSuccessful;
            __block NSError *_error = nil;
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _error = error;
                               }];
            
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventuallyBeforeTimingOutAfter(2.0)] beTrue];
            [[expectFutureValue(_error) shouldEventuallyBeforeTimingOutAfter(2.0)] beNil];
        });
        
    });
    
    
    context(@"sign in successful, but account not confirmed", ^{
        
        it(@"should reject with unconfirmed error", ^{
            
            hoodieServer.signInResponseType = HOOSignInResponseTypeSuccessUnconfirmedUser;
            
            __block NSError *_signInError;
            __block BOOL _signInSuccessful;
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _signInError = error;
                               }];
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventuallyBeforeTimingOutAfter(2.0)] beFalse];
            [[expectFutureValue(@(_signInError.code)) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:@(HOOAccountUnconfirmedError)];
        });
    });

    context(@"sign in not successful", ^{
        
        it(@"should reject with unauthorized error", ^{
            
            hoodieServer.signInResponseType = HOOSignInResponseTypeErrorWrongCredentials;

            __block NSError *_signInError;
            __block BOOL _signInSuccessful;
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _signInError = error;
                               }];
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventuallyBeforeTimingOutAfter(2.0)] beFalse];
            [[expectFutureValue(@(_signInError.code)) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:@(HOOAccountSignInWrongCredentialsError)];
        });
    });

#pragma mark - Change password
    
    context(@"change password successful", ^{
        
        it(@"should sign in user", ^{
            
            hoodieServer.signUpResponseType = HOOSignUpResponseTypeSuccess;
            hoodieServer.signInResponseType = HOOSignInResponseTypeSuccessConfirmedUser;
            hoodieServer.getUserResponseType = HOOGetUserResponseTypeSuccessConfirmedUser;
            
            [account stub:@selector(username) andReturn:@"joe@example.com"];
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                      }];
            
            [[[account shouldEventuallyBeforeTimingOutAfter(2.0)] receive] signInUserWithName:@"joe@example.com"
                                                            password:@"newSecret"
                                                            onSignIn:any()];
        });
    });

    context(@"change password and sign in successful", ^{
        
        it(@"should return onPasswordChangeFinished(YES,nil)",^{
            
            [account stub:@selector(username) andReturn:@"joe@example.com"];
            
            __block BOOL _passwordChangeSuccessful = NO;
            __block NSError *_error;
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                          _passwordChangeSuccessful = passwordChangeSuccessful;
                          _error = error;
                      }];
            
            [[expectFutureValue(@(_passwordChangeSuccessful)) shouldEventuallyBeforeTimingOutAfter(2.0)] beTrue];
            [[expectFutureValue(_error) shouldEventuallyBeforeTimingOutAfter(2.0)] beNil];
        });
    });


    context(@"change password not successful", ^{
        
        it(@"should return with error", ^{
            
            __block BOOL _passwordChangeSuccessful;
            __block NSError *_error;
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                          _passwordChangeSuccessful = passwordChangeSuccessful;
                          _error = error;
                      }];
            
            [[expectFutureValue(@(_passwordChangeSuccessful)) shouldEventuallyBeforeTimingOutAfter(2.0)] beFalse];
            [[expectFutureValue(_error) shouldEventuallyBeforeTimingOutAfter(2.0)] beNonNil];
        });
    });
    
#pragma mark - Anonymous signup
    
    context(@"anonymous signup succesful", ^{
       
        it(@"should exist an anonymous account with username = hoodieID", ^{
            
            [account anonymousSignUpOnFinished:^(BOOL signUpSuccessful, NSError *error) {
                
            }];
           
            [[expectFutureValue(@(account.hasAnonymousAccount)) shouldEventuallyBeforeTimingOutAfter(2.0)] beTrue];
            [[expectFutureValue(account.username) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:hoodie.hoodieID];
        });
    });
    
  });

SPEC_END