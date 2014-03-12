//
// Created by Katrin Apel on 07/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOHelper.h"


@implementation HOOHelper

+ (NSString *)generateHoodieId
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);

    // Hoodie Id must fulfill these criteria:
    // - all lowercase
    // - must begin with a character

    uuidString = [uuidString lowercaseString];
    NSString *randomStartLetter = [NSString stringWithFormat:@"%c", arc4random_uniform(26) + 'a'];
    NSString *hoodieId = [uuidString stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                             withString:randomStartLetter];

    return hoodieId;
}

@end