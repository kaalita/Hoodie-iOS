//
//  iOS_Tests.m
//  iOS_Tests
//
//  Created by Katrin Apel on 24/03/14.
//
//

#import "Kiwi.h"
#import "HOOHoodie.h"

SPEC_BEGIN(HOOHoodieSpec)

describe(@"initWithBaseURL:", ^{
    
    it(@"should store the base url", ^{
        NSURL *baseURL = [NSURL URLWithString:@"http://couch.example.com"];
        [[[[HOOHoodie alloc] initWithBaseURL:baseURL].baseURL should] equal:baseURL];
    });
    
    it(@"should remove trailing slash from passed URL", ^{
        NSURL *baseURLWithTrailingSlash = [NSURL URLWithString:@"http://couch.example.com/"];
        NSURL *baseURL = [NSURL URLWithString:@"http://couch.example.com"];
        [[[[HOOHoodie alloc] initWithBaseURL:baseURLWithTrailingSlash].baseURL should] equal:baseURL];
    });
    
});

SPEC_END