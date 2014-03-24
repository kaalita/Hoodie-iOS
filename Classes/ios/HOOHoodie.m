//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOHoodie.h"
#import "HOOHelper.h"

NSString * const HOOKeyForHoodieId = @"HoodieId";

@implementation HOOHoodie

- (id)initWithBaseURL:(NSURL *)baseURL
{
    self = [super init];
    if (self)
    {
        self.baseURL = [self removeTrailingSlashFromURL:baseURL];
        
        NSString *savedHoodieId = [self savedHoodieId];
        if(savedHoodieId)
        {
            self.hoodieId = savedHoodieId;
        }
        else
        {
            self.hoodieId = [HOOHelper generateHoodieId];
        }
        
        self.store = [[HOOStore alloc] initWithHoodie:self];
        self.account = [[HOOAccount alloc] initWithHoodie:self];
    }
    
    return self;
}

- (NSString *)savedHoodieId
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * savedHoodieId = [userDefaults stringForKey: HOOKeyForHoodieId];
    return savedHoodieId;
}

- (void)saveHoodieId
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if(self.hoodieId)
    {
        [userDefaults setObject:self.hoodieId forKey:HOOKeyForHoodieId];
    }
    else
    {
        [userDefaults removeObjectForKey:HOOKeyForHoodieId];
    }
    [userDefaults synchronize];
}

- (void)setHoodieId:(NSString *)hoodieId
{
    _hoodieId = hoodieId;
    [self saveHoodieId];
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