//
// Created by Katrin Apel on 04/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#ifndef __AuthenticationDelegate
#define __AuthenticationDelegate

@protocol AuthenticationDelegate

- (void)userDidSignIn;
- (void)userDidSignUp;

@end

#endif
