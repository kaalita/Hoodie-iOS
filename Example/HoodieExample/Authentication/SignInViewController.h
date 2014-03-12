//
// Created by Katrin Apel on 03/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthenticationDelegate.h"

@class HOOHoodie;

@interface SignInViewController : UITableViewController

@property (nonatomic, strong) HOOHoodie *hoodie;
@property (nonatomic, assign) id <AuthenticationDelegate> authenticationDelegate;

- (id) initWithHoodie: (HOOHoodie *) hoodie;

@end