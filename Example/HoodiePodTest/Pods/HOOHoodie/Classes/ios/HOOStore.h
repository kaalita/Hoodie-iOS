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

- (NSArray *)findAllByType: (NSString *) type;

- (void)clearLocalData;

@end