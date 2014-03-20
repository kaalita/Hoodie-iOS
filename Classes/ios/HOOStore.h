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

- (void)saveDocument:(NSDictionary *)dictionary withType:(NSString *)type;

- (void)removeDocumentWithID: (NSString *)objectId
                     andType: (NSString *)type
                   onRemoval: (void (^)(BOOL removalSuccesful, NSError * error))onRemovalFinished;

- (NSArray *)findAllByType: (NSString *) type;

- (void)clearLocalData;

@end