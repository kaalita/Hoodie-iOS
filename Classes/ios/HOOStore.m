//
// Created by Katrin Apel on 22/02/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOStore.h"
#import "CouchbaseLite.h"
#import "HOOHelper.h"
#import "HOOHoodie.h"
#import "HOOErrorGenerator.h"

NSString * const HOOStoreChangeNotification = @"HOOStoreChangeNotification";

@interface HOOStore ()

@property(nonatomic, strong) HOOHoodie *hoodie;
@property(nonatomic, strong) CBLManager *manager;
@property(nonatomic, strong) CBLDatabase *database;
@property(nonatomic, strong) CBLReplication *pushReplication;
@property(nonatomic, strong) CBLReplication *pullReplication;
@property(nonatomic, strong) CBLQuery *queryAllDocsByType;

@end

@implementation HOOStore

- (id)initWithHoodie: (HOOHoodie *) hoodie
{
    self = [super init];
    if(self)
    {
        self.hoodie = hoodie;
        self.manager = [[CBLManager alloc] init];
        [self setupDatabase];
    }

    return self;
}

#pragma mark - Local database: creation & tear down

- (void)setupDatabase
{
    NSError*createLocalDatabaseError;
    self.database = [self.manager databaseNamed:@"hoodie" error:&createLocalDatabaseError];
    if (self.database)
    {
        [self subscribeToDatabaseChangeNotification];
        [self setupQueries];
    }
    else
    {
        NSLog(@"HOODIE - Error creating local database: %@", [createLocalDatabaseError localizedDescription]);
    }
}

- (void)tearDownDatabase
{
    self.pullReplication = nil;
    self.pushReplication = nil;

    [self unsubscribeFromDatabaseChangeNotifications];
    [[self.database viewNamed:@"allDocsByType"] deleteView];

    NSError *databaseDeletionError;
    [self.database deleteDatabase:&databaseDeletionError];
    if(databaseDeletionError)
    {
        NSLog(@"HOODIE - Error deleting local database: %@", [databaseDeletionError localizedDescription]);
    }
}

- (void)setupQueries
{
    [[self.database viewNamed: @"allDocsByType"] setMapBlock: MAPBLOCK({
        id type = [doc objectForKey: @"type"];
        if (type) emit(type, doc);
    }) reduceBlock: nil version: @"1.1"];

    self.queryAllDocsByType = [[self.database viewNamed:@"allDocsByType"] createQuery];
}

#pragma mark - Database Change Notification

- (void)databaseChanged:(NSNotification *)notification
{
    NSNotificationCenter*notificationCenter = [NSNotificationCenter defaultCenter];
    
    if(![NSThread isMainThread])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [notificationCenter postNotificationName:HOOStoreChangeNotification object:nil];
        });
    }
    else
    {
        [notificationCenter postNotificationName:HOOStoreChangeNotification object:nil];
    }
}

-(void) subscribeToDatabaseChangeNotification
{
    NSNotificationCenter*notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(databaseChanged:)
                               name:kCBLDatabaseChangeNotification
                             object:nil];
}

-(void) unsubscribeFromDatabaseChangeNotifications
{
    NSNotificationCenter*notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:kCBLDatabaseChangeNotification
                                object:nil];

}

#pragma mark -  Public methods

- (void)saveObject:(NSDictionary *)object
          withType:(NSString *)type
            onSave:(void (^)(NSDictionary *object, NSError * error))onSaveFinished
{
    CBLDocument *documentToSave;
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:object];

    NSString *jsonStringOfCurrentDate = [CBLJSON JSONObjectWithDate:[NSDate new]];

    NSString *couchDocumentId = [self couchDocumentIdWithId:[HOOHelper generateHoodieId] andType:type];
    documentToSave = [self.database documentWithID:couchDocumentId];
    [properties setObject:self.hoodie.hoodieId forKey:@"createdBy"];
    [properties setObject:jsonStringOfCurrentDate forKey:@"createdAt"];
    [properties setObject:type forKey:@"type"];
    [properties setObject:jsonStringOfCurrentDate forKey:@"updatedAt"];

    NSError *saveDocumentError;
    [documentToSave putProperties:properties error:&saveDocumentError];

    if(saveDocumentError)
    {
        onSaveFinished(nil,saveDocumentError);
    }
    else
    {
        NSDictionary *savedHoodieObject = [self hoodieObjectFromCouchObject: documentToSave.properties];
        onSaveFinished(savedHoodieObject, nil);
    }
}

- (void)updateObjectWithId:(NSString *)objectId
                   andType:(NSString *)type
            withProperties:(NSDictionary *)properties
                  onUpdate:(void (^)(NSDictionary *, NSError *))onUpdateFinished
{
    NSString *couchId = [self couchDocumentIdWithId:objectId andType:type];
    CBLDocument *documentToUpdate = [self.database existingDocumentWithID:couchId];
    
    if(documentToUpdate)
    {
        NSMutableDictionary *documentProperties = [[NSMutableDictionary alloc] initWithDictionary: documentToUpdate.properties];
        [documentProperties addEntriesFromDictionary:properties];
        documentProperties[@"updatedAt"] = [CBLJSON JSONObjectWithDate:[NSDate new]];

        NSError *error;
        [documentToUpdate putProperties:documentProperties error:&error];
        if(error)
        {
            onUpdateFinished(nil, error);
        }
        else
        {
            NSDictionary *updatedHoodieObject = [self hoodieObjectFromCouchObject: documentToUpdate.properties];
            onUpdateFinished(updatedHoodieObject, nil);
        }
    }
    else
    {
        NSError *noDocumentError = [HOOErrorGenerator errorWithType:HOOStoreDocumentDoesNotExistError];
        onUpdateFinished(NO, noDocumentError);
    }
}

- (void)removeObjectWithID:(NSString *)objectId
                   andType:(NSString *)type
                 onRemoval:(void (^)(BOOL removalSuccessful, NSError * error))onRemovalFinished
{
    NSString *couchDocumentId = [self couchDocumentIdWithId:objectId andType:type];
    CBLDocument *documentToRemove = [self.database documentWithID:couchDocumentId];
    if(!documentToRemove)
    {
        NSError *noDocumentError = [HOOErrorGenerator errorWithType:HOOStoreDocumentDoesNotExistError];
        onRemovalFinished(NO, noDocumentError);
    }
    else
    {
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:documentToRemove.properties];
        properties[@"_deleted"] = [NSNumber numberWithBool:YES];
        NSError *removalError;
        [documentToRemove putProperties:properties error:&removalError];
        if(!removalError)
        {
            onRemovalFinished(YES, nil);
        }
        else
        {
            onRemovalFinished(NO, removalError);
        }
    }
}

- (NSDictionary *)findObjectWithId: (NSString *) objectId andType: (NSString *)type
{
    NSString *couchDocumentId = [self couchDocumentIdWithId:objectId andType:type];
    
    CBLDocument *document = [self.database existingDocumentWithID:couchDocumentId];
    if(document)
    {
        NSDictionary *hoodieObject = [self hoodieObjectFromCouchObject:document.properties];
        return hoodieObject;
    }
    
    return nil;
}

- (NSArray *)findAllObjectsWithType:(NSString *)type
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];

    NSError *error;
    CBLQueryEnumerator *queryEnumerator = [self.queryAllDocsByType run:&error];
    for(CBLQueryRow* row in queryEnumerator)
    {
        if([[row.document.properties valueForKey:@"type"] isEqualToString:type])
        {
            NSDictionary *hoodieObject = [self hoodieObjectFromCouchObject:row.document.properties];
            [resultArray addObject:hoodieObject];
        }
    }

    return resultArray;
}

- (NSDictionary *)hoodieObjectFromCouchObject: (NSDictionary *)couchObject
{
    NSMutableDictionary *hoodieObject = [[NSMutableDictionary alloc] init];

    NSEnumerator *keyEnumerator = couchObject.keyEnumerator;
    for(NSString *key in keyEnumerator)
    {
        if([key isEqualToString:@"_id"])
        {
            NSString *couchId = [couchObject valueForKey:key];
            NSArray *couchIdComponents = [couchId componentsSeparatedByString:@"/"];
            if([couchIdComponents count] == 2)
            {
                hoodieObject[@"id"] = couchIdComponents[1];
                hoodieObject[@"type"] = couchIdComponents[0];
            }
            else
            {
                NSLog(@"HOODIE - Error creating Hoodie object from CouchDB object with _id: %@", couchId);
            }
        }
        else
        {
            NSString *value = [couchObject valueForKey:key];
            [hoodieObject setObject:value forKey:key];
        }
    }
    return hoodieObject;
}

- (void)setRemoteStoreURL:(NSURL *)remoteStoreURL
{
    NSArray *replications = [self.database replicationsWithURL:remoteStoreURL exclusively:YES];

    self.pullReplication = replications[0];
    self.pullReplication.persistent = YES;

    self.pushReplication = replications[1];
    self.pushReplication.persistent = YES;

    [self.pullReplication start];
    [self.pushReplication start];
}

- (void)clearLocalData
{
    [self tearDownDatabase];
    [self setupDatabase];
}

# pragma mark - Helper methods

- (NSString *)couchDocumentIdWithId:(NSString *)objectId andType:(NSString *)type
{
    return [NSString stringWithFormat:@"%@/%@",type,objectId];
}


@end