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
    [notificationCenter postNotificationName:HOOStoreChangeNotification object:nil];
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

- (void)saveDocument:(NSDictionary *)dictionary withType:(NSString *)type
{
    CBLDocument *documentToSave;
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:dictionary];

    NSString *jsonStringOfCurrentDate = [CBLJSON JSONObjectWithDate:[NSDate new]];

    // The document already exists
    if ([dictionary valueForKey:@"_id"])
    {
        documentToSave = [self.database documentWithID:[dictionary valueForKey:@"_id"]];
        [properties setObject:[documentToSave valueForKey:@"createdBy"] forKey:@"createdBy"];
        [properties setObject:[documentToSave valueForKey:@"createdAt"] forKey:@"createdAt"];

        // ??
        [properties setObject:[documentToSave valueForKey:@"_rev"] forKey:@"_rev"];
    }
    else
    {
        NSString *newDocumentId = [NSString stringWithFormat:@"%@/%@",type,[HOOHelper generateHoodieId]];
        documentToSave = [self.database documentWithID:newDocumentId];
        [properties setObject:self.hoodie.hoodieId forKey:@"createdBy"];
        [properties setObject:jsonStringOfCurrentDate forKey:@"createdAt"];
    }

    [properties setObject:type forKey:@"type"];
    [properties setObject:jsonStringOfCurrentDate forKey:@"updatedAt"];

    NSError *saveDocumentError;
    [documentToSave putProperties:properties error:&saveDocumentError];

    if(saveDocumentError)
    {
        NSLog(@"Error saving document: %@", [saveDocumentError localizedDescription]);
    }
}

- (void)removeDocumentWithID:(NSString *)objectId
                     andType:(NSString *)type
                   onRemoval:(void (^)(BOOL removalSuccesful, NSError * error))onRemovalFinished
{
    NSString *documentId = [NSString stringWithFormat:@"%@/%@",type,objectId];
    CBLDocument *documentToRemove = [self.database documentWithID:documentId];
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

- (NSArray *)findAllByType:(NSString *)type
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

@end