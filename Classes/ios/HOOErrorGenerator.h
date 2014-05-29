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


/**
 * A helper class that is used internally to generate the Hoodie errors
 */
@interface HOOErrorGenerator : NSObject

/**
 * Generates an NSError instance for the given Hoodie error type
 *
 * @param errorType One of the given
 * @return NSError for the given Hoodie error type
 */
+ (NSError *) errorWithType: (HOOErrorType) errorType;

@end