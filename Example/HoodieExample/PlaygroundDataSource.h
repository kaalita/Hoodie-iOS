//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HOOStore;

typedef void (^TableViewCellConfigureBlock)(id cell, id item);

@interface PlaygroundDataSource : NSObject <UITableViewDataSource>

- (id)initWithStore:(HOOStore *)store
     cellIdentifier:(id)cellIdentifier
 cellConfigureBlock:(TableViewCellConfigureBlock)cellConfigureBlock;

@end