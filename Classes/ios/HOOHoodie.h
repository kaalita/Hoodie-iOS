//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOOStore.h"
#import "HOOAccount.h"

@class HOOHoodieAPIClient;

@interface HOOHoodie : NSObject

@property(nonatomic, strong) NSString *hoodieID;
@property(nonatomic, strong) HOOStore *store;
@property(nonatomic, strong) HOOAccount *account;
@property (nonatomic, readonly) HOOHoodieAPIClient *apiClient;

- (id)initWithBaseURLString:(NSString *)baseURLString;

@end