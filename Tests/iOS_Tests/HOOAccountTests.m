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
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
        
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        
        NSString *path = @"/_api/_users/org.couchdb.user:user%2Fjoe";
        if([request.URL.path isEqualToString:path])
        {
            return [OHHTTPStubsResponse responseWithFileAtPath:@"Stub01-NewUserSuccess.json"
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"text/json"}];
        }
        
        if([request.URL.path isEqualToString:@"/_api/_session"])
        {
            return [OHHTTPStubsResponse responseWithFileAtPath:@"Stub02-SignInSuccess.json"
                                                    statusCode:200
                                                       headers:@{@"Content-Type":@"text/json"}];
        }
        
        return nil;
    }];
    
    HOOHoodie *hoodie = [HOOHoodie mock];
    [hoodie stub:@selector(baseURL) andReturn: [NSURL URLWithString: baseURL]];
    [hoodie stub:@selector(hoodieID) andReturn:@"uuid123"];
    [hoodie stub:@selector(store) andReturn:[HOOStore mock]];
    
    HOOAccount *account = [[HOOAccount alloc] initWithHoodie:hoodie];
    
    context(@"signup with username and password", ^{
        
        it(@"should be rejected if username not set", ^{
            
            __block BOOL _signUpSuccessful;
            __block NSError *_error = nil;
           
            [account signUpUserWithName:@"" password:@"secret" onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                _signUpSuccessful = signUpSuccessful;
                _error = error;
            }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] equal:@(0)];
            [[expectFutureValue(@(_error.code)) shouldEventually] equal:@(HOOAccountSignUpUsernameEmptyError)];
        });
        
    });
});

SPEC_END