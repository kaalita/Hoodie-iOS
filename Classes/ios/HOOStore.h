//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const HOOStoreChangeNotification;

@class HOOHoodie;

@interface HOOStore : NSObject

@property (nonatomic, strong) NSURL *remoteStoreURL;

- (id)initWithHoodie: (HOOHoodie *) hoodie;

- (void)saveObject:(NSDictionary *)object
          withType:(NSString *)type
            onSave:(void (^)(NSDictionary *object, NSError * error))onSaveFinished;

// Save
// Update
// SaveOrUpdate

- (void)updateObjectWithId:(NSString *)objectId
                   andType:(NSString *)type
            withProperties:(NSDictionary *)properties
                  onUpdate:(void (^)(BOOL updateSuccessful, NSError * error))onUpdateFinished;


- (void)removeObjectWithID:(NSString *)objectId
                   andType:(NSString *)type
                 onRemoval:(void (^)(BOOL removalSuccessful, NSError * error))onRemovalFinished;

- (void)clearLocalData;

// Finding objects

- (NSDictionary *)findObjectWithId:(NSString *)objectId
                           andType:(NSString *)type;

- (NSArray *)findAllObjectsWithType:(NSString *)type;





@end