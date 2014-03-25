//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOOStore.h"
#import "HOOAccount.h"

@interface HOOHoodie : NSObject

@property(nonatomic, strong) NSString *hoodieID;
@property(nonatomic, strong) NSURL *baseURL;
@property(nonatomic, strong) HOOStore *store;
@property(nonatomic, strong) HOOAccount *account;

- (id)initWithBaseURL:(NSURL *)baseURL;

@end