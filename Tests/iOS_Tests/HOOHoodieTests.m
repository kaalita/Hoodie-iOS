//
//  HOOHoodieTests.m
//  iOS_Tests
//
//  Created by Katrin Apel on 24/03/14.
//
//

#import "Kiwi.h"
#import "HOOHoodie.h"
#import "HOOHoodieAPIClient.h"

SPEC_BEGIN(HOOHoodieSpec)

describe(@"HOOHoodie", ^{
    
    context(@"on initialization", ^{

        it(@"should store the base url and append /_api", ^{
            
            NSString *baseURLString = @"http://couch.example.com";
            HOOHoodie *hoodie = [[HOOHoodie alloc] initWithBaseURLString:baseURLString];
            [[[hoodie.apiClient.apiURL absoluteString] should] equal:[NSString stringWithFormat:@"%@/_api",baseURLString]];
        });
    
        it(@"should handle base url string with trailing slashes", ^{
            
            NSString *baseURLStringWithTrailingSlash = @"http://couch.example.com/";
            HOOHoodie *hoodie = [[HOOHoodie alloc] initWithBaseURLString:baseURLStringWithTrailingSlash];
            [[[hoodie.apiClient.apiURL absoluteString] should] equal:[NSString stringWithFormat:@"%@_api",baseURLStringWithTrailingSlash]];
        });
    });
});

SPEC_END