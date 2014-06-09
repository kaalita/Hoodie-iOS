//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const HOOStoreChangeNotification;

@class HOOHoodie;

@interface HOOStore : NSObject

-(id)initWithHoodie:(HOOHoodie *) hoodie;

-(void)setAccountDatabaseForUsername:(NSString *)username;

-(void)saveObject:(NSDictionary *)object
        withType:(NSString *)type
        onSave:(void (^)(NSDictionary *savedObject, NSError * error))onSaveFinished;

-(void)updateObjectWithID:(NSString *)objectID
                  andType:(NSString *)type
           withProperties:(NSDictionary *)properties
                 onUpdate:(void (^)(NSDictionary *updatedObject, NSError * error))onUpdateFinished;

-(void)removeObjectWithID:(NSString *)objectID
                  andType:(NSString *)type
                onRemoval:(void (^)(BOOL removalSuccessful, NSError * error))onRemovalFinished;

-(void)clearLocalData;

-(NSDictionary *)findObjectWithID:(NSString *)objectID
                        andType:(NSString *)type;

-(NSArray *)findAllObjectsWithType:(NSString *)type;

@end