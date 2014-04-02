//
//  ChangePasswordViewController.h
//  HoodieExample
//
//  Created by Katrin Apel on 03/04/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountDelegate.h"

@class HOOAccount;

@interface ChangePasswordViewController : UITableViewController

@property (nonatomic, weak) id <AccountDelegate> delegate;
@property (nonatomic, strong) HOOAccount *account;

-(id)initWithAccount:(HOOAccount *)account;

@end
