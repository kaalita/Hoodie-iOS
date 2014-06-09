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
#import "HOOHoodieAPIClient.h"

SPEC_BEGIN(HOOAccountSpec)

const float ktimeout = 5.0;

describe(@"HOOAccount", ^{
    
    NSString *baseURL = @"http://localhost.:6001";
    
    HOOHoodie *hoodie = [[HOOHoodie alloc] initWithBaseURLString:baseURL];
    
    FakeHoodieServer *hoodieServer = [[FakeHoodieServer alloc] initWithSignUpResponseType:HOOSignUpResponseTypeSuccess
                                                                       signInResponseType:HOOSignInResponseTypeSuccessConfirmedUser
                                                                      getUserResponseType:HOOGetUserResponseTypeSuccessConfirmedUser];
    
#pragma mark - Sign up

    context(@"signup with username and password", ^{
        
        it(@"should be rejected if username not set", ^{
            
            __block BOOL _signUpSuccessful;
            __block NSError *_error = nil;
           
            [hoodie.account signUpUserWithName:@""
                                      password:@"secret"
                                      onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                                   
                                   _signUpSuccessful = signUpSuccessful;
                                   _error = error;
            }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] beFalse];
            [[expectFutureValue(@(_error.code)) shouldEventually] equal:@(HOOAccountSignUpUsernameEmptyError)];
        });

        it(@"should lowercase the username", ^{
            
            [hoodie.account signUpUserWithName:@"JOE"
                                      password:@"secret"
                                      onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                               }];
            
            [[expectFutureValue(hoodie.account.username) shouldEventuallyBeforeTimingOutAfter(ktimeout)] equal:@"joe"];
        });
    });

    context(@"signup successful", ^{
        
        it(@"should sign in user", ^{
            
            [hoodie.account signUpUserWithName:@"joe"
                                      password:@"secret"
                                      onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                               }];
            
            [[[hoodie.account shouldEventuallyBeforeTimingOutAfter(ktimeout)] receive] signInUserWithName:@"joe"
                                                                                          password:@"secret"
                                                                                          onSignIn:any()];
        });
    });
    
    context(@"signup has a conflict error", ^{
        
        it(@"should reject signup and return a username already taken error", ^{
            
            hoodieServer.signUpResponseType = HOOSignUpResponseTypeErrorUsernameTaken;
            
            __block NSError *_signUpError;
            __block BOOL _signUpSuccessful;
            
            [hoodie.account signUpUserWithName:@"exists@example.com"
                                      password:@"secret"
                                      onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                                   
                                   _signUpSuccessful = signUpSuccessful;
                                   _signUpError = error;
                               }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beFalse];
            [[expectFutureValue(@(_signUpError.code)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] equal:@(HOOAccountSignUpUsernameTakenError)];
        });
    });
    
    
#pragma mark - Sign in
    
    context(@"sign in successful and account is confirmed", ^{
        
        it(@"should call onSignIn(YES, nil)", ^{

            hoodieServer.signInResponseType = HOOSignInResponseTypeSuccessConfirmedUser;
            
            __block BOOL _signInSuccessful;
            __block NSError *_error = nil;
            
            [hoodie.account signInUserWithName:@"joe@example.com"
                                      password:@"secret"
                                      onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _error = error;
                               }];
            
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beTrue];
            [[expectFutureValue(_error) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beNil];
        });
        
    });
    
    
    context(@"sign in successful, but account not confirmed", ^{
        
        it(@"should reject with unconfirmed error", ^{
            
            hoodieServer.signInResponseType = HOOSignInResponseTypeSuccessUnconfirmedUser;
            
            __block NSError *_signInError;
            __block BOOL _signInSuccessful;
            
            [hoodie.account signInUserWithName:@"joe@example.com"
                                      password:@"secret"
                                      onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _signInError = error;
                               }];
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beFalse];
            [[expectFutureValue(@(_signInError.code)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] equal:@(HOOAccountUnconfirmedError)];
        });
    });

    context(@"sign in not successful", ^{
        
        it(@"should reject with unauthorized error", ^{
            
            hoodieServer.signInResponseType = HOOSignInResponseTypeErrorWrongCredentials;

            __block NSError *_signInError;
            __block BOOL _signInSuccessful;
            
            [hoodie.account signInUserWithName:@"joe@example.com"
                                      password:@"secret"
                                      onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _signInError = error;
                               }];
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beFalse];
            [[expectFutureValue(@(_signInError.code)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] equal:@(HOOAccountSignInWrongCredentialsError)];
        });
    });

#pragma mark - Change password
    
    context(@"change password successful", ^{
        
        it(@"should sign in user", ^{
            
            hoodieServer.signUpResponseType = HOOSignUpResponseTypeSuccess;
            hoodieServer.signInResponseType = HOOSignInResponseTypeSuccessConfirmedUser;
            hoodieServer.getUserResponseType = HOOGetUserResponseTypeSuccessConfirmedUser;
            
            [hoodie.account stub:@selector(username) andReturn:@"joe@example.com"];
            
            [hoodie.account changeOldPassword:@"secret"
                                toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                      }];
            
            [[[hoodie.account shouldEventuallyBeforeTimingOutAfter(ktimeout)] receive] signInUserWithName:@"joe@example.com"
                                                                                                 password:@"newSecret"
                                                                                                 onSignIn:any()];
        });
    });

    context(@"change password and sign in successful", ^{
        
        it(@"should return onPasswordChangeFinished(YES,nil)",^{
            
            [hoodie.account stub:@selector(username) andReturn:@"joe@example.com"];
            
            __block BOOL _passwordChangeSuccessful = NO;
            __block NSError *_error;
            
            [hoodie.account changeOldPassword:@"secret"
                                toNewPassword:@"newSecret"
                             onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                          _passwordChangeSuccessful = passwordChangeSuccessful;
                          _error = error;
                      }];
            
            [[expectFutureValue(@(_passwordChangeSuccessful)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beTrue];
            [[expectFutureValue(_error) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beNil];
        });
    });


    context(@"change password not successful", ^{        
        
        it(@"should return with error", ^{
            
            hoodieServer.getUserResponseType = HOOGetUserResponseTypeErrorUserNotFound;
            
            __block BOOL _passwordChangeSuccessful;
            __block NSError *_error;
            
            [hoodie.account changeOldPassword:@"secret"
                                toNewPassword:@"newSecret"
                             onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                          _passwordChangeSuccessful = passwordChangeSuccessful;
                          _error = error;
                      }];
            
            [[expectFutureValue(@(_passwordChangeSuccessful)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beFalse];
            [[expectFutureValue(_error) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beNonNil];
        });
    });
    
#pragma mark - Anonymous signup
    
    context(@"anonymous signup succesful", ^{
       
        it(@"should exist an anonymous account with username = hoodieID", ^{
            
            [hoodie.account anonymousSignUpOnFinished:^(BOOL signUpSuccessful, NSError *error) {
                
            }];
           
            [[expectFutureValue(@(hoodie.account.hasAnonymousAccount)) shouldEventuallyBeforeTimingOutAfter(ktimeout)] beTrue];
            [[expectFutureValue(hoodie.account.username) shouldEventuallyBeforeTimingOutAfter(ktimeout)] equal:hoodie.hoodieID];
        });
    });
    
  });

SPEC_END