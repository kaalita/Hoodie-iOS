//
// Created by Katrin Apel on 07/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOHelper.h"

@implementation HOOHelper

+ (NSString *)generateHoodieId
{
    int hoodieIdLength = 7;
    NSString *alphabet  = @"0123456789abcdefghijklmnopqrstuvwxyz";
    int alphabetLength = [alphabet length];
    
    NSMutableString *hoodieId = [NSMutableString stringWithCapacity:hoodieIdLength];
    for (NSUInteger i = 0U; i < hoodieIdLength; i++)
    {
        u_int32_t r = arc4random() % alphabetLength;
        unichar c = [alphabet characterAtIndex:r];
        [hoodieId appendFormat:@"%C", c];
    }
    NSLog(@"hoodie id: %@", hoodieId);
    return hoodieId;
}

@end