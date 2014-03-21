//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "PlaygroundDataSource.h"
#import "HOOStore.h"

@interface PlaygroundDataSource ()

@property (strong, nonatomic) HOOStore *store;
@property (copy, nonatomic) NSString *cellIdentifier;
@property (copy, nonatomic) TableViewCellConfigureBlock configureCellBlock;

@end

@implementation PlaygroundDataSource

- (id)initWithStore:(HOOStore *)store
     cellIdentifier:(id)cellIdentifier
 cellConfigureBlock:(TableViewCellConfigureBlock)cellConfigureBlock
{
    self = [super init];
    if(self)
    {
        self.store = store;
        self.cellIdentifier = cellIdentifier;
        self.configureCellBlock = [cellConfigureBlock copy];
    }

    return self;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.store findAllObjectsWithType:@"todo"][(NSUInteger) indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.store findAllObjectsWithType:@"todo"].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                            forIndexPath:indexPath];
    id item = [self itemAtIndexPath:indexPath];
    self.configureCellBlock(cell, item);
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSDictionary *todoItem = [self itemAtIndexPath:indexPath];
        [self.store removeDocumentWithID:todoItem[@"id"]
                                 andType:todoItem[@"type"]
                               onRemoval:^(BOOL removalSuccesful, NSError *error) {
                                   if(error)
                                   {
                                       NSLog(@"Error deleting document: %@",[error localizedDescription]);
                                   }
        }];
    }
}

@end