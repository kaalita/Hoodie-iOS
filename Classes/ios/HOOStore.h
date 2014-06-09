//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const HOOStoreChangeNotification;

@class HOOHoodie;

/**
 * The local data store of HOOHoodie.
 * Also resonsible for keeping the local and remote data in sync.
 */
@interface HOOStore : NSObject

-(id)initWithHoodie:(HOOHoodie *) hoodie;

/**
 * Default initializer.
 * @param hoodie Your HOOHoodie instance
 */
- (id)initWithHoodie:(HOOHoodie *) hoodie;

/**
 * Saves a new object to the local store.
 * @param object A dictionary with the key/values of the new object, that should be saved.
 * @param type The type of the object. Must not be nil or empty.
 * @param block Evaluate the error object to see if the save was successful (error = nil). savedObject is the object that was just saved. It contains all the keys reserved for Hoodie: id, type, createdAt, updatedAt, createdBy.
 * @warning Don't use the reserved keys for the dictionary: id, type, createdAt, updatedAt, createdBy
 */
- (void)saveObject:(NSDictionary *)object
          withType:(NSString *)type
            onSave:(void (^)(NSDictionary *savedObject, NSError * error))onSaveFinished;

/**
 * Updates an existing object with the given properties.
 *
 * @param objectID The id of the object that should be updated. When saving an object for the first time, Hoodie adds a value for the key "id". Use this.
 * @param type The type of the object that should be updated.
 * @param properties A dictionary with the key/value pairs that should be updated.
 * @param block Evaluate the error object to see if the update was successful (error = nil). updatedObject is the the object that was just updated.
 */
- (void)updateObjectWithID:(NSString *)objectID
                   andType:(NSString *)type
            withProperties:(NSDictionary *)properties
                  onUpdate:(void (^)(NSDictionary *updatedObject, NSError * error))onUpdateFinished;

/**
 * Removes an existing object from the store.
 *
 * @param objectID The id of the object that should be updated. When saving an object for the first time, Hoodie adds a value for the key "id". Use this.
 * @param type The type of the object
 * @param block Evaluate removalSuccessful and error to see if Hoodie could successfully remove the object.
 */
- (void)removeObjectWithID:(NSString *)objectID
                   andType:(NSString *)type
                 onRemoval:(void (^)(BOOL removalSuccessful, NSError * error))onRemovalFinished;

/**
 * Clears all local data so the store is empty afterwards.
 */
- (void)clearLocalData;

/**
 * Finds an object in the local store with the given id and of the given type.
 * 
 * @param objectID The id of the object that should be updated. When saving an object for the first time, Hoodie adds a value for the key "id". Use this.
 * @param type The type of the object
 * @return The object with the given id and type, if it exists; nil otherwise
 */
- (NSDictionary *)findObjectWithID:(NSString *)objectID
                           andType:(NSString *)type;

/**
 * Finds all objects in the local store of the given type.
 *
 * @param type The type of the objects
 * @return An array of all the objects of the given type. Nil if no objects of that type exist.
 */
- (NSArray *)findAllObjectsWithType:(NSString *)type;

/**
 * Tells the local store the name of the user on the Hoodie server.
 * The store then sets up the replications from the local store to the remote database for the user
 * @param username Name of the user
 */
-(void)setAccountDatabaseForUsername:(NSString *)username;

@end