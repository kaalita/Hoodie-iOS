//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HOOStore.h"
#import "HOOAccount.h"

@class HOOHoodieAPIClient;

/**
 * Create a HOOHoodie instance as the base for user and data management
 */
@interface HOOHoodie : NSObject

/** 
 * The unique ID of your Hoodie. 
 * A random ID will be generated on creation of a new HOOHoodie instance.
 * This ID will be persisted until the user signs out or clears the local data.
 */
@property(nonatomic, strong) NSString *hoodieID;

/** 
 * The Hoodie data store. 
 * The store also handles the synching of the local data with the data in the remote store in the Hoodie Backend.
 */
@property(nonatomic, strong) HOOStore *store;

/** 
 * The Hoodie user account.
 * Handles account creation, sign in and signout.
 */
@property(nonatomic, strong) HOOAccount *account;
@property (nonatomic, readonly) HOOHoodieAPIClient *apiClient;

/**
 * Default initializer
 * @param baseURLString URL string where your Hoodie Backend is located.
 */
- (id)initWithBaseURLString:(NSString *)baseURLString;

@end