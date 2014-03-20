//
//  PlaygroundCell.m
//  HoodiePlayground
//
//  Created by Katrin Apel on 22/02/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "PlaygroundCell.h"

@implementation PlaygroundCell

+ (UINib *)nib
{
    return [UINib nibWithNibName:@"PlaygroundCell" bundle:nil];;
}

+ (NSString *)cellIdentifier
{
    return @"PlaygroundCell";
}

- (void)configureForTodoItem:(NSDictionary *)dictionary
{
    self.todoItem = dictionary;
    self.label.text = [dictionary valueForKey:@"title"];
}
@end
