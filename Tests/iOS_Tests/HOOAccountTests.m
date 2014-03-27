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
    });
    
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
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] equal:@(0)];
            [[expectFutureValue(@(_error.code)) shouldEventually] equal:@(HOOAccountSignUpUsernameEmptyError)];
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
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] equal:@(0)];
            [[expectFutureValue(@(_signUpError.code)) shouldEventually] equal:@(HOOAccountSignUpUsernameTakenError)];
        });
    });

  });

SPEC_END