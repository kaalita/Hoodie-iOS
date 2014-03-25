//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOHoodie.h"
#import "HOOHelper.h"

NSString * const HOOKeyForHoodieID = @"HoodieID";

@implementation HOOHoodie

- (id)initWithBaseURL:(NSURL *)baseURL
{
    self = [super init];
    if (self)
    {
        self.baseURL = [self removeTrailingSlashFromURL:baseURL];
        
        NSString *savedHoodieID = [self savedHoodieID];
        if(savedHoodieID)
        {
            self.hoodieID = savedHoodieID;
        }
        else
        {
            self.hoodieID = [HOOHelper generateHoodieID];
        }
        
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

- (NSURL *)removeTrailingSlashFromURL: (NSURL *) url
{
    NSString *urlString = url.absoluteString;
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/+$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:urlString
                                                               options:0
                                                                 range:NSMakeRange(0, [urlString length])
                                                          withTemplate:@""];    
    return [NSURL URLWithString:modifiedString];
}

@end