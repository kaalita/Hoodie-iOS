# HOOHoodie

[![Version](http://cocoapod-badges.herokuapp.com/v/HOOHoodie/badge.png)](http://cocoadocs.org/docsets/HOOHoodie)
[![Platform](http://cocoapod-badges.herokuapp.com/p/HOOHoodie/badge.png)](http://cocoadocs.org/docsets/HOOHoodie)
[![Build Status](https://travis-ci.org/kaalita/Hoodie-iOS.svg?branch=v0.2.0)](https://travis-ci.org/kaalita/Hoodie-iOS)

Hoodie-iOS is a library which connects to the Hoodie backend API.
(See http://hood.ie/ for more information on Hoodie)
As local storage the awesome Couchbase Lite framework is used, which also handles the replication to and from the server.

It doesn't support the full API and functionality yet (see issues to see what's still missing). 
Currently supported functionality:
- Anonymous Sign up
- Sign up (sign up with username and password)
- Sign in
- Sign out
- Change password of account
- Saving new objects
- Removing objects
- Updating objects
- Retrieving all saved objects of the user by type
- Replication to and from user database on the server

## Usage

To run the example project; clone the repo, and run `pod install` from the Example directory first.

Then install the Hoodie Server and create a new Hoodie app, which will be the backend for your iOS app (see http://hood.ie/#installation for instructions).

## Installation

HOOHoodie is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "HOOHoodie"

## Documentation

To get started with Hoodie-iOS, first install the Hoodie Server and create and start a new Hoodie app (see http://hood.ie/#installation for instructions).

####Creating a new hoodie instance

```Objective-C
#import "HOOHoodie.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // This is the URL of the Hoodie API, after you started your Hoodie app
    NSURL *baseURL = [NSURL URLWithString:@"http://localhost:6001/_api"];
    
    // Create new Hoodie instance with URL to your Hoodie API
    self.hoodie = [[HOOHoodie alloc] initWithBaseURL:baseURL];
}
```

####Anonymous sign up

```Objective-C
[self.hoodie.account anonymousSignUpOnFinished:^(BOOL signUpSuccessful, NSError *error) {               

            }];
```

####Sign up new user

```Objective-C
    [self.hoodie.account signUpUserWithName:@"username"
                                   password:@"password"
                                   onSignUp:^(BOOL signUpSuccessful, NSError *error) {
    }];
```

####Sign in existing user

If the user signed in succesfully, Hoodie signs in the user automatically on that device on startup, until the user signs out explicitly.

```Objective-C
    [self.hoodie.account signInUserWithName:@"username"
                                   password:@"password"
                                   onSignIn:^(BOOL signInSuccessful, NSError *error) {
    }];
```

####Sign out current user

```Objective-C
    [self.hoodie.account signOutOnFinished:^(BOOL signOutSuccessful, NSError *error) {
        [self updateSignInStateDependentElements];
    }];
```

####Change password of existing user

```Objective-C
    [self.hoodie.account changeOldPassword:self.currentPasswordInputField.text
                             toNewPassword:self.passwordInputField.text
                          onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                          }];

```

####Saving objects

The Hoodie store currently only accepts NSDictionaries as objects to store.

Reserved keys that are set automatically by the Hoodie store are:
 _id, _rev, type, createdBy, createdAt, updatedAt 

```Objective-C
    NSDictionary *newTodo = @{@"title": @"This is a todo"};
    [self.hoodie.store saveObject:newTodo 
                         withType:@"todo"
                           onSave:^(NSDictionary *object, NSError *error) {
    }];
```

####Update existing object

```Objective-C
 [self.store updateObjectWithID:todoItem[@"id"]
                        andType:todoItem[@"type"]      
                 withProperties:@{@"title": textField.text}
                       onUpdate:^(NSDictionary *updatedObject, NSError *error) {
}];
```

####Remove object

```Objective-C
 [self.store removeObjectWithID:todoItem[@"id"]
                        andType:todoItem[@"type"]                                                                                           onRemoval:^(BOOLremovalSuccessful,NSError*error) {
}];
```

####Retrieving objects

```Objective-C
    NSArray *myTodos = [self.store findAllByType:@"todo"];
```
## Source

The source code is available on Github:
https://github.com/kaalita/Hoodie-iOS

## Contributing

Anyone and everyone is welcome to contribute. Please take a moment to
review the [guidelines for contributing](CONTRIBUTING.md).

* [Bug reports](CONTRIBUTING.md#bugs)
* [Feature requests](CONTRIBUTING.md#features)
* [Pull requests](CONTRIBUTING.md#pull-requests)

## Author

Katrin Apel, katrin.apel@gmail.com

## License

HOOHoodie is available under the Apache 2.0 license. See the LICENSE file for more info.

