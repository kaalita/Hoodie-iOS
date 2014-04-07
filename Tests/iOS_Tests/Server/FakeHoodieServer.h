//
//  FakeHoodieServer.h
//  HOOHoodieTests
//
//  Created by Katrin Apel on 04/04/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    HOOSignUpResponseTypeSuccess = 1,
    HOOSignUpResponseTypeErrorUsernameTaken = 2,
} HOOSignUpResponseType;

typedef enum {
    HOOSignInResponseTypeSuccessConfirmedUser = 1,
    HOOSignInResponseTypeSuccessUnconfirmedUser = 2,
    HOOSignInResponseTypeErrorWrongCredentials = 3
} HOOSignInResponseType;

typedef enum {
    HOOGetUserResponseTypeSuccessConfirmedUser = 1,
    HOOGetUserResponseTypeSuccessUnconfirmedUser = 2,
} HOOGetUserResponseType;


@interface FakeHoodieServer : NSObject

@property (nonatomic, assign) HOOSignUpResponseType signUpResponseType;
@property (nonatomic, assign) HOOSignInResponseType signInResponseType;
@property (nonatomic, assign) HOOGetUserResponseType getUserResponseType;

-(id)initWithSignUpResponseType:(HOOSignUpResponseType) signUpResponseType
             signInResponseType:(HOOSignInResponseType) signInResponseType
            getUserResponseType:(HOOGetUserResponseType) getUserResponseType;

@end
