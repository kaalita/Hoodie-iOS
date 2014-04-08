//
// Created by Katrin Apel on 07/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOHelper.h"

@implementation HOOHelper

+ (NSString *)generateHoodieID
{
    int hoodieIDLength = 7;
    NSString *alphabet  = @"0123456789abcdefghijklmnopqrstuvwxyz";
    NSUInteger alphabetLength = [alphabet length];
    
    NSMutableString *hoodieID = [NSMutableString stringWithCapacity:hoodieIDLength];
    for (NSUInteger i = 0U; i < hoodieIDLength; i++)
    {
        u_int32_t r = arc4random() % alphabetLength;
        unichar c = [alphabet characterAtIndex:r];
        [hoodieID appendFormat:@"%C", c];
    }
    return hoodieID;
}

@end