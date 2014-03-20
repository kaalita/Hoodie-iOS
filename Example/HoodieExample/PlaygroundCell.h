//
//  PlaygroundCell.h
//  HoodiePlayground
//
//  Created by Katrin Apel on 22/02/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaygroundCell : UITableViewCell

@property (strong, nonatomic) NSDictionary *todoItem;
@property (weak, nonatomic) IBOutlet UILabel *label;

+ (UINib *)nib;
+ (NSString *)cellIdentifier;

- (void)configureForTodoItem:(NSDictionary *)dictionary;

@end
