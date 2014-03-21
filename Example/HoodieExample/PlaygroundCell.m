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
    return [UINib nibWithNibName:@"PlaygroundCell" bundle:nil];
}

+ (NSString *)cellIdentifier
{
    return @"PlaygroundCell";
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.textField.hidden = YES;
        self.textField.userInteractionEnabled = NO;
    }
    
    return self;
}

- (void)showEditingMode: (BOOL) editing
{
    if(editing)
    {
        self.textField.userInteractionEnabled = YES;
        self.textField.text = self.label.text;
        self.label.hidden = YES;
        self.textField.hidden = NO;
    }
    else
    {
        self.textField.userInteractionEnabled = NO;
        self.label.hidden = NO;
        self.textField.hidden = YES;
    }
}

- (void)configureForTodoItem:(NSDictionary *)dictionary
{
    self.todoItem = dictionary;
    self.label.text = [dictionary valueForKey:@"title"];
}
@end
