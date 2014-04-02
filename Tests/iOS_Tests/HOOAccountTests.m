//
//  HOOAccountTests.m
//  iOS_Tests
//
//  Created by Katrin Apel on 24/03/14.
//
//

#import "Kiwi.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "HOOHoodie.h"
#import "HOOErrorGenerator.h"

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
    
    __block HOOAccount *account;
    
    beforeEach(^{
        account = [[HOOAccount alloc] initWithHoodie:hoodie];
        [OHHTTPStubs removeAllStubs];
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
        
        
        it(@"should make correct Hoodie API request", ^{
            
            __block NSString *path;
            __block NSString *method;
            __block NSString *contentType;
            __block NSDictionary *body;
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                path = request.URL.path;
                method = request.HTTPMethod;
                contentType = [request allHTTPHeaderFields][@"Content-type"];
                
                NSError *error;
                body = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                       options:0
                                                         error:&error];
                return nil;
            }];
            
            [account signUpUserWithName:@"randomusername"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                               }];
            
            [[expectFutureValue(path) shouldEventually] equal:@"/_api/_users/org.couchdb.user:user/randomusername"];
            [[expectFutureValue(method) shouldEventually] equal:@"PUT"];
            
            NSUInteger locationOfJSONContentType = [contentType rangeOfString:@"application/json"].location;
            [[expectFutureValue(@(locationOfJSONContentType)) shouldNotEventually] equal:@(NSNotFound)];
            
            [[expectFutureValue(body[@"name"]) shouldEventually] equal:@"user/randomusername"];
            [[expectFutureValue(body[@"password"]) shouldEventually] equal:@"secret"];
            [[expectFutureValue(body[@"type"]) shouldEventually] equal:@"user"];
        });
        
        
        it(@"should lowercase the username", ^{
            
            __block NSString *path;
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                path = request.URL.path;
                return nil;
            }];
            
            [account signUpUserWithName:@"JOE"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
            }];
            [[expectFutureValue(path) shouldEventually] equal:@"/_api/_users/org.couchdb.user:user/joe"];
        });
    });
    
    context(@"signup successful", ^{
        
        it(@"should sign in user", ^{
            
            __block NSString *path;
            __block NSString *method;
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                if([request.URL.path isEqualToString:@"/_api/_users/org.couchdb.user:user/joe"])
                {
                    NSDictionary * response = @{
                                                @"ok": @(YES),
                                                @"id'": @"org.couchdb.user:joe",
                                                @"rev": @"1-a0134f4a9909d3b20533285c839ed830"
                                                };
                    NSError *error;
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                        options:NSJSONWritingPrettyPrinted
                                                                          error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:jsonData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
                }
                else
                {
                    path = request.URL.path;
                    method = request.HTTPMethod;
                }
                
                return nil;
            }];
            
            [account signUpUserWithName:@"joe"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                                   
                               }];
            
            [[expectFutureValue(path) shouldEventually] equal:@"/_api/_session"];
            [[expectFutureValue(method) shouldEventually] equal:@"POST"];
        });
    });

    
    context(@"signup has a conflict error", ^{
        
        it(@"should reject signup and return a username already taken error", ^{
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                NSDictionary *response = @{
                                           @"error": @"conflict",
                                           @"reason": @"Document update conflict."
                                          };
                    
                NSError *error;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                    options:NSJSONWritingPrettyPrinted
                                                                      error:&error];
                    
                return [OHHTTPStubsResponse responseWithData:jsonData
                                                  statusCode:409
                                                     headers:@{@"Content-Type":@"text/json"}];
                
            }];
            
            __block NSError *_signUpError;
            __block BOOL _signUpSuccessful;
            
            [account signUpUserWithName:@"exists@example.com"
                               password:@"secret"
                               onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                                   
                                   _signUpSuccessful = signUpSuccessful;
                                   _signUpError = error;
                               }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] beFalse];
            [[expectFutureValue(@(_signUpError.code)) shouldEventually] equal:@(HOOAccountSignUpUsernameTakenError)];
        });
    });
    
#pragma mark - Sign in
    
    context(@"sign in with username and password", ^{
        
        it(@"should make correct Hoodie API request", ^{
            
            __block NSString *path;
            __block NSString *method;
            __block NSDictionary *body;
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                path = request.URL.path;
                method = request.HTTPMethod;
                
                NSError *error;
                body = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                       options:0
                                                         error:&error];
                return nil;
            }];
            
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
            }];
            
            [[expectFutureValue(path) shouldEventually] equal:@"/_api/_session"];
            [[expectFutureValue(method) shouldEventually] equal:@"POST"];
            [[expectFutureValue(body[@"name"]) shouldEventually] equal:@"user/joe@example.com"];
            [[expectFutureValue(body[@"password"]) shouldEventually] equal:@"secret"];
        });
    });
    
    context(@"sign in successful and account is confirmed", ^{
        
        it(@"should call onSignIn(YES, nil)", ^{
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                if([request.URL.path isEqualToString:@"/_api/_session"])
                {
                    NSDictionary * response = @{
                                                @"ok": @(YES),
                                                @"name'": @"user/joe@example.com",
                                                @"roles": @[@"hash123",@"confirmed"]
                                                };
                    NSError *error;
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                        options:NSJSONWritingPrettyPrinted
                                                                          error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:jsonData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
                }
                
                return nil;
            }];

            
            __block BOOL _signInSuccessful;
            __block NSError *_error = nil;
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   
                                   _signInSuccessful = signInSuccessful;
                                   _error = error;
                               }];
            
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventually] beTrue];
            [[expectFutureValue(_error) shouldEventually] beNil];
        });
        
    });
    
    
    context(@"sign in successful, but account not confirmed", ^{
        
        it(@"should reject with unconfirmed error", ^{
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                NSDictionary *response = @{
                                           @"ok": @(YES),
                                           @"name": @"user/joe@example.com",
                                           @"roles": @[]
                                           };
                
                NSError *error;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                    options:NSJSONWritingPrettyPrinted
                                                                      error:&error];
                
                return [OHHTTPStubsResponse responseWithData:jsonData
                                                  statusCode:200
                                                     headers:@{@"Content-Type":@"text/json"}];
            }];
            
            __block NSError *_signInError;
            __block BOOL _signInSuccessful;
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   _signInSuccessful = signInSuccessful;
                                   _signInError = error;
                               }];
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventually] beFalse];
            [[expectFutureValue(@(_signInError.code)) shouldEventually] equal:@(HOOAccountUnconfirmedError)];
        });
    });

    context(@"sign in not successful", ^{
        
        it(@"should reject with unauthorized error", ^{
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                NSDictionary *response = @{
                                           @"error": @"unauthorized",
                                           @"reason": @"Name or password is incorrect."
                                           };
                
                NSError *error;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                    options:NSJSONWritingPrettyPrinted
                                                                      error:&error];
                
                return [OHHTTPStubsResponse responseWithData:jsonData
                                                  statusCode:401
                                                     headers:@{@"Content-Type":@"text/json"}];
            }];
            
            __block NSError *_signInError;
            __block BOOL _signInSuccessful;
            
            [account signInUserWithName:@"joe@example.com"
                               password:@"secret"
                               onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                   _signInSuccessful = signInSuccessful;
                                   _signInError = error;
                               }];
            
            [[expectFutureValue(@(_signInSuccessful)) shouldEventually] beFalse];
            [[expectFutureValue(@(_signInError.code)) shouldEventually] equal:@(HOOAccountSignInWrongCredentialsError)];
        });
    });

#pragma mark - Change password
    
    context(@"change password", ^{
        
        it(@"should make correct Hoodie API request", ^{
            
            __block NSString *path;
            __block NSString *method;
            __block NSDictionary *body;
            
            [account stub:@selector(username) andReturn:@"joe@example.com"];
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                path = request.URL.path;
                method = request.HTTPMethod;
                
                NSError *error;
                body = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                       options:0
                                                         error:&error];
                return nil;
            }];
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                      }];
            
            [[expectFutureValue(path) shouldEventually] equal:@"/_api/_users/org.couchdb.user:user/joe@example.com"];
            [[expectFutureValue(method) shouldEventually] equal:@"PUT"];
            [[expectFutureValue(body[@"_id"]) shouldEventually] equal:@"org.couchdb.user:user/joe@example.com"];
            [[expectFutureValue(body[@"name"]) shouldEventually] equal:@"user/joe@example.com"];
            [[expectFutureValue(body[@"type"]) shouldEventually] equal:@"user"];
            [[expectFutureValue(body[@"password"]) shouldEventually] equal:@"newSecret"];
            [[expectFutureValue(body[@"updatedAt"]) shouldEventually] beNonNil];
            [[expectFutureValue(body[@"createdAt"]) shouldEventually] beNil];
            [[expectFutureValue(body[@"salt"]) shouldEventually] beNil];
            [[expectFutureValue(body[@"password_sha"]) shouldEventually] beNil];
        });
    });
    
    context(@"change password successful", ^{
        
        it(@"should sign in user", ^{
            
            [account stub:@selector(username) andReturn:@"joe@example.com"];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                    NSDictionary *response = @{
                                               @"ok": @"true",
                                               @"id": @"org.couchdb.user:user/joe@example.com",
                                               @"rev": @"2-345"
                                               };
                    NSError *error;
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                        options:NSJSONWritingPrettyPrinted
                                                                          error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:jsonData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
            }];
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
            }];
            
            [[[account shouldEventually] receive] signInUserWithName:@"joe@example.com"
                                                            password:@"newSecret"
                                                            onSignIn:any()];
        });
    });
    
    context(@"change password and sign in successful", ^{
        
        it(@"should return onPasswordChangeFinished(YES,nil)",^{
            
            [account stub:@selector(username) andReturn:@"joe@example.com"];
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                if([request.URL.path isEqualToString:@"/_api/_users/org.couchdb.user:user/joe@example.com"])
                {
                    NSDictionary *response = @{
                                               @"ok": @"true",
                                               @"id": @"org.couchdb.user:user/joe@example.com",
                                               @"rev": @"2-345"
                                               };
                    NSError *error;
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                        options:NSJSONWritingPrettyPrinted
                                                                          error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:jsonData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
                }
                else
                {
                    NSDictionary * response = @{
                                                @"ok": @(YES),
                                                @"name'": @"user/joe@example.com",
                                                @"roles": @[@"hash123",@"confirmed"]
                                                };
                    NSError *error;
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                        options:NSJSONWritingPrettyPrinted
                                                                          error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:jsonData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
                }
            }];
            
            __block BOOL _passwordChangeSuccessful = NO;
            __block NSError *_error;
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                          _passwordChangeSuccessful = passwordChangeSuccessful;
                          _error = error;
                      }];
            
            [[expectFutureValue(@(_passwordChangeSuccessful)) shouldEventually] beTrue];
            [[expectFutureValue(_error) shouldEventually] beNil];
        });
    });

    context(@"change password not successful", ^{
        
        it(@"should return with error", ^{
            
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                NSDictionary *response = @{
                                           @"name": @"HoodieError",
                                           @"message": @"Something wrong"
                                           };
                
                NSError *error;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                    options:NSJSONWritingPrettyPrinted
                                                                      error:&error];
                
                return [OHHTTPStubsResponse responseWithData:jsonData
                                                  statusCode:409
                                                     headers:@{@"Content-Type":@"text/json"}];
            }];
            
            
            __block BOOL _passwordChangeSuccessful;
            __block NSError *_error;
            
            [account changeOldPassword:@"secret"
                         toNewPassword:@"newSecret"
                      onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          
                          _passwordChangeSuccessful = passwordChangeSuccessful;
                          _error = error;
                      }];
            
            [[expectFutureValue(@(_passwordChangeSuccessful)) shouldEventually] beFalse];
            [[expectFutureValue(_error) shouldEventually] beNonNil];
        });
    });
  });

SPEC_END