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
        
        it(@"should lowercase the username", ^{
            
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
                
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                
                if([request.URL.path isEqualToString:@"/_api/_session"])
                {
                    NSError *error;
                    NSDictionary *requestBody = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                                                options:0
                                                                                  error:&error];
                    NSLog(@"%@",requestBody);
                    NSString *username = [requestBody[@"name"] componentsSeparatedByString:@"/"][1];
                    NSLog(@"sign in user %@",username);
                    
                    NSDictionary *responseDictionary = @{@"name":[NSString stringWithFormat:@"user/%@",username],
                                                         @"roles":@[@"hash123",@"confirmed"]};
                    
                    NSData * responseData = [NSJSONSerialization dataWithJSONObject:responseDictionary
                                                                            options:NSJSONWritingPrettyPrinted
                                                                              error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:responseData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
                }
                else
                {
                    NSString *username = request.URL.pathComponents.lastObject;
                    
                    NSDictionary *responseDictionary = @{@"id":[NSString stringWithFormat:@"org.couchdb.user:user/%@",username],
                                                         @"ok":@"1",
                                                         @"rev":@"1-123"};
                    
                    NSError * error;
                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:responseDictionary options:NSJSONWritingPrettyPrinted error:&error];
                    
                    return [OHHTTPStubsResponse responseWithData:jsonData
                                                      statusCode:200
                                                         headers:@{@"Content-Type":@"text/json"}];
                }
                return nil;
            }];
            
            __block BOOL _signUpSuccessful;
            __block NSError *_error = nil;
            
            [account signUpUserWithName:@"JOE" password:@"secret" onSignUp:^(BOOL signUpSuccessful, NSError *error) {
                _signUpSuccessful = signUpSuccessful;
                _error = error;
            }];
            
            [[expectFutureValue(@(_signUpSuccessful)) shouldEventually] equal:@(1)];
            [[expectFutureValue(_error) shouldEventually] beNil];
            [[expectFutureValue(account.username) shouldEventually] equal:@"joe"];
        });

        
    });
});

SPEC_END