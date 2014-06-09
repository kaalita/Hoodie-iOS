//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOHoodie.h"
#import "HOOHelper.h"
#import "HOOHoodieAPIClient.h"

NSString * const HOOKeyForHoodieID = @"HoodieID";

@interface HOOHoodie ()

@property (nonatomic, strong) HOOHoodieAPIClient *apiClient;

@end

@implementation HOOHoodie

- (id)initWithBaseURLString:(NSString *)baseURLString
{
    self = [super init];
    if (self)
    {
        NSString *savedHoodieID = [self savedHoodieID];
        if(savedHoodieID)
        {
            self.hoodieID = savedHoodieID;
        }
        else
        {
            self.hoodieID = [HOOHelper generateHoodieID];
        }
        
        self.apiClient = [[HOOHoodieAPIClient alloc] initWithBaseURLString:baseURLString hoodie:self];
        self.store = [[HOOStore alloc] initWithHoodie:self];
        self.account = [[HOOAccount alloc] initWithHoodie:self];
    }
    
    return self;
}

- (NSString *)savedHoodieID
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * savedHoodieID = [userDefaults stringForKey: HOOKeyForHoodieID];
    return savedHoodieID;
}

- (void)saveHoodieID
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if(self.hoodieID)
    {
        [userDefaults setObject:self.hoodieID forKey:HOOKeyForHoodieID];
    }
    else
    {
        [userDefaults removeObjectForKey:HOOKeyForHoodieID];
    }
    [userDefaults synchronize];
}

- (void)setHoodieID:(NSString *)hoodieID
{
    _hoodieID = hoodieID;
    [self saveHoodieID];
}

@end