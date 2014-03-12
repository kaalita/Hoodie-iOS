//
//  Created by Katrin Apel on 03/03/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "SignUpViewController.h"
#import "HOOHoodie.h"
#import "AuthenticationDelegate.h"
#import "SVProgressHUD.h"

@interface SignUpViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameInputField;
@property (weak, nonatomic) IBOutlet UITextField *passwordInputField;

@end

@implementation SignUpViewController

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.usernameInputField)
    {
        [self.passwordInputField becomeFirstResponder];
    }

    if(textField == self.passwordInputField)
    {
        [textField resignFirstResponder];
        [self signUpUser];
    }
    return YES;
}

- (void)signUpUser
{
    [SVProgressHUD showWithStatus:@"Signing up" maskType:SVProgressHUDMaskTypeBlack];
    [self.hoodie.account signUpUserWithName:self.usernameInputField.text
                                   password:self.passwordInputField.text
                                   onSignUp:^(BOOL signUpSuccessful, NSError *error) {

                                       [SVProgressHUD dismiss];

                                       if(signUpSuccessful)
                                       {
                                           [self.authenticationDelegate userDidSignUp];
                                       }
                                       else
                                       {
                                           UIAlertView *alertView;
                                           alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                                  message:error.localizedFailureReason
                                                                                 delegate:self
                                                                        cancelButtonTitle:@"Ok"
                                                                        otherButtonTitles:nil];
                                           [alertView show];
                                       }
    }];
}

@end
