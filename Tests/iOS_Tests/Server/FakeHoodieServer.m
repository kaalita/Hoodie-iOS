//
//  FakeHoodieServer.m
//  HOOHoodieTests
//
//  Created by Katrin Apel on 04/04/14.
//
//

#import "FakeHoodieServer.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

typedef enum {
    HOORequestTypeUnknown = 0,
    HOORequestSignUp = 1,
    HOORequestTypeSignIn = 2,
    HOORequestTypeGetUser = 3,
    HOORequestTypeSignOut = 4
} HOORequestType;

@implementation FakeHoodieServer

- (id)initWithSignUpResponseType:(HOOSignUpResponseType)signUpResponseType
              signInResponseType:(HOOSignInResponseType)signInResponseType
             getUserResponseType:(HOOGetUserResponseType) getUserResponseType
{
    self = [super init];
    if(self)
    {
        self.signUpResponseType = signUpResponseType;
        self.signInResponseType = signInResponseType;
        self.getUserResponseType = getUserResponseType;
        
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
            
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            
            NSDictionary *body;
            
            if([request HTTPBody])
            {
                NSError *jsonParseError;
                body = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                       options:0
                                                         error:&jsonParseError];
            }
            
            switch ([self typeOfRequest:request])
            {
                case HOORequestSignUp:
                    
                {
                    NSError *error = NULL;
                    NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:@"^/_api/_users/org.couchdb.user:user/"
                                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                                     error:&error];
                    
                    NSMutableString *username = [[NSMutableString alloc] initWithString: request.URL.path];
                    [usernameRegex replaceMatchesInString:username
                                                  options:0
                                                    range:NSMakeRange(0, username.length)
                                             withTemplate:@""];
                    
                    if([body[@"type"] isEqualToString:@"user"] && [body[@"name"] isEqualToString:[NSString stringWithFormat:@"user/%@",username]])
                    {
                        return [self signUpResponseForUsername:username];
                    }
                }
                    break;
                    
                case HOORequestTypeGetUser:
                {
                    if(self.getUserResponseType == HOOGetUserResponseTypeErrorUserNotFound)
                    {
                        return [self documentMissingResponse];
                    }
                    else
                    {
                        NSError *error = NULL;
                        NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:@"^/_api/_users/org.couchdb.user:user/"
                                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                                         error:&error];
                        
                        NSMutableString *username = [[NSMutableString alloc] initWithString: request.URL.path];
                        [usernameRegex replaceMatchesInString:username
                                                      options:0
                                                        range:NSMakeRange(0, username.length)
                                                 withTemplate:@""];
                        
                        return [self getUserDocumentResponseForUsername:username andHoodieID:@"uuid123"];
                    }
                }
                    break;
                    
                case HOORequestTypeSignIn:
                {
                    NSError *error = NULL;
                    NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:@"^user/"
                                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                                     error:&error];
                    
                    NSMutableString *username = [[NSMutableString alloc] initWithString: body[@"name"]];
                    [usernameRegex replaceMatchesInString:username
                                                  options:0
                                                    range:NSMakeRange(0, username.length)
                                             withTemplate:@""];
                    
                    return [self signInResponseForUsername:username andHoodieID:@"uuid123"];
                }
                    break;
    
                    
                default:
                    break;
            }
            
            return nil;
        }];
    }
    
    return self;
}

-(OHHTTPStubsResponse *)signUpResponseForUsername:(NSString *)username
{
    switch (self.signUpResponseType)
    {
        case HOOSignUpResponseTypeSuccess:
        {
            NSDictionary * response = @{
                                        @"ok": @(YES),
                                        @"id": [NSString stringWithFormat:@"org.couchdb.user:user/%@",username],
                                        @"rev": @"1-abc"
                                        };
            NSError *error;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:&error];
            
            return [OHHTTPStubsResponse responseWithData:jsonData
                                              statusCode:200
                                                 headers:@{@"Content-Type":@"text/json"}];
            
        }
            break;
            
        case HOOSignUpResponseTypeErrorUsernameTaken:
        {
            NSDictionary *response = @{
                                       @"error": @"conflict",
                                       @"reason": @"Document update conflict."
                                       };
            
            NSError *error;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:&error];
            
            return [OHHTTPStubsResponse responseWithData:jsonData
                                              statusCode:409
                                                 headers:@{@"Content-Type":@"text/json"}];
        }
            break;
            
            
        default:
            return nil;
            break;
    }
}

-(OHHTTPStubsResponse *)getUserDocumentResponseForUsername:(NSString *)username
                                               andHoodieID:(NSString *)hoodieID
{
    NSDictionary *confirmedUserDocument = @{
                                            @"_id": [NSString stringWithFormat:@"org.couchdb.user:%@",username],
                                            @"_rev": @"1-abc",
                                            @"createdAt": @"someday",
                                            @"database": [NSString stringWithFormat:@"user/%@",hoodieID],
                                            @"derived_key": @"derived key",
                                            @"hoodieId": hoodieID,
                                            @"iterations": @(10),
                                            @"name": [NSString stringWithFormat:@"user/%@",username],
                                            @"password_scheme": @"pbkdf2",
                                            @"roles": @[ hoodieID,
                                                         @"confirmed",
                                                         [NSString stringWithFormat:@"hoodie:read:user/%@",hoodieID],
                                                         [NSString stringWithFormat:@"hoodie:write:user/%@",hoodieID]
                                                       ],
                                            @"salt": @"salt",
                                            @"signedUpAt": @"someday",
                                            @"type": @"user",
                                            @"updatedAt": @"someday"
                                            };
    
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:confirmedUserDocument
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&error];
    
    return [OHHTTPStubsResponse responseWithData:jsonData
                                      statusCode:200
                                         headers:@{@"Content-Type":@"text/json"}];
    
}

-(OHHTTPStubsResponse *)documentMissingResponse
{
    NSDictionary *documentNotFound = @{
                                       @"error": @"not_found",
                                       @"reason": @"missing"
                                       };
    
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:documentNotFound
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&error];
    
    return [OHHTTPStubsResponse responseWithData:jsonData
                                      statusCode:404
                                         headers:@{@"Content-Type":@"text/json"}];
}

-(OHHTTPStubsResponse *)signInResponseForUsername:(NSString *)username
                                      andHoodieID:(NSString *)hoodieID
{
    
    switch (self.signInResponseType)
    {
        case HOOSignInResponseTypeSuccessConfirmedUser:
        {
            NSDictionary * response = @{
                                        @"ok": @(YES),
                                        @"name'": @"user/joe@example.com",
                                        @"roles": @[@"hash123",@"confirmed"]
                                        };
            NSError *error;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:&error];
            
            return [OHHTTPStubsResponse responseWithData:jsonData
                                              statusCode:200
                                                 headers:@{@"Content-Type":@"text/json"}];
        }
            break;
        
        case HOOSignInResponseTypeSuccessUnconfirmedUser:
        {
            NSDictionary * response = @{
                                        @"ok": @(YES),
                                        @"name'": @"user/joe@example.com",
                                        @"roles": @[]
                                        };
            NSError *error;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:&error];
            
            return [OHHTTPStubsResponse responseWithData:jsonData
                                              statusCode:200
                                                 headers:@{@"Content-Type":@"text/json"}];

        }
            break;
            
        case HOOSignInResponseTypeErrorWrongCredentials:
        {
            NSDictionary * response = @{
                                        @"userCtx": @{ @"name": @"null"}
                                        };
            NSError *error;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:&error];
            
            return [OHHTTPStubsResponse responseWithData:jsonData
                                              statusCode:401
                                                 headers:@{@"Content-Type":@"text/json"}];
        }
            break;
            
        default:
            return nil;
            break;
    }
}

-(HOORequestType)typeOfRequest:(NSURLRequest *)request
{
    NSString *method = request.HTTPMethod;
    NSString *path = request.URL.path;
    
    NSError *regexError = NULL;
    NSRegularExpression *userPathRegex = [NSRegularExpression regularExpressionWithPattern:@"^/_api/_users/org.couchdb.user:user/[_.@a-z0-9]*$"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&regexError];
    
    if([userPathRegex matchesInString:path options:0 range:NSMakeRange(0, path.length)].count == 1)
    {
        if([method isEqualToString:@"PUT"])
        {
            return HOORequestSignUp;
        }
        
        if([method isEqualToString:@"GET"])
        {
            return HOORequestTypeGetUser;
        }
    }
    
    if([path isEqualToString:@"/_api/_session"])
    {
        if([method isEqualToString:@"POST"])
        {
            return HOORequestTypeSignIn;
        }
    }
    
    return HOORequestTypeUnknown;
}


@end
