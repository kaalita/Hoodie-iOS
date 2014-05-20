//
//  Created by Katrin Apel on 03/03/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HOOHoodie;
@protocol AuthenticationDelegate;

@interface SignUpViewController : UITableViewController

@property(nonatomic, assign) id <AuthenticationDelegate> authenticationDelegate;
@property (strong, nonatomic) HOOHoodie *hoodie;

-(id)initWithHoodie:(HOOHoodie *)hoodie;

@end
