//
// Created by Katrin Apel on 06/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HOOAccountSignUpUsernameEmptyError = -101,
    HOOAccountSignUpUsernameTakenError = -102,
    HOOAccountUnconfirmedError = -103,
    HOOAccountSignInWrongCredentialsError = -104,
    HOOStoreDocumentDoesNotExistError = -105
} HOOErrorType;

@interface HOOErrorGenerator : NSObject

+ (NSError *) errorWithType: (HOOErrorType) errorType;

@end