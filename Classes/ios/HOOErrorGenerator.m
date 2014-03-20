//
// Created by Katrin Apel on 06/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "HOOErrorGenerator.h"


@implementation HOOErrorGenerator

+ (NSError *)errorWithType:(HOOErrorType)errorType
{
    NSError *error;
    NSString *errorDomain;
    NSString *errorDescription;
    NSString *errorFailureReason;
    NSString *errorRecoverySuggestion;

    switch(errorType)
    {
        case HOOAccountSignUpUsernameEmptyError:
        {
            errorDomain =  @"hoodie.account";
            errorDescription =  NSLocalizedString(@"Sign up failed", nil);
            errorFailureReason =  NSLocalizedString(@"Username can not be empty.", nil);
            errorRecoverySuggestion = NSLocalizedString(@"Please enter a username.", nil);
        }
            break;

        case HOOAccountSignUpUsernameTakenError:
        {
            errorDomain =  @"hoodie.account";
            errorDescription =  NSLocalizedString(@"Sign up failed", nil);
            errorFailureReason =  NSLocalizedString(@"Username already taken.", nil);
            errorRecoverySuggestion = NSLocalizedString(@"Please try another username.", nil);

        }
            break;

        case HOOAccountUnconfirmedError:
        {
            errorDomain =  @"hoodie.account";
            errorDescription =  NSLocalizedString(@"Account not confirmed", nil);
            errorFailureReason =  NSLocalizedString(@"The account as not been confirmed yet.", nil);
            errorRecoverySuggestion = NSLocalizedString(@"Please try again later.", nil);
        }
            break;

        case HOOAccountSignInWrongCredentialsError:
        {
            errorDomain =  @"hoodie.account";
            errorDescription =  NSLocalizedString(@"Sign in failed", nil);
            errorFailureReason =  NSLocalizedString(@"Wrong username or password", nil);
            errorRecoverySuggestion = NSLocalizedString(@"Please make sure the entered username and/or password are correct.", nil);

        }
            break;
            
        case HOOStoreDocumentDoesNotExistError:
        {
            errorDomain =  @"hoodie.store";
            errorDescription =  NSLocalizedString(@"Document does not exist", nil);
            errorFailureReason =  NSLocalizedString(@"A document with the given id and type does not exist.", nil);
            errorRecoverySuggestion = NSLocalizedString(@"Please make sure the given id and type are correct.", nil);
            
        }
            break;
    }

    NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: errorDescription,
            NSLocalizedFailureReasonErrorKey: errorFailureReason,
            NSLocalizedRecoverySuggestionErrorKey: errorRecoverySuggestion
    };
    error = [NSError errorWithDomain:errorDomain
                                code:errorType
                            userInfo:userInfo];

    return error;
}

@end