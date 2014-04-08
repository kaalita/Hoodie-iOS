//
//  ChangePasswordViewController.m
//  HoodieExample
//
//  Created by Katrin Apel on 03/04/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "HOOHoodie.h"

@interface ChangePasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *currentPasswordInputField;
@property (weak, nonatomic) IBOutlet UITextField *passwordInputField;

@end

@implementation ChangePasswordViewController

-(id)initWithAccount:(HOOAccount *)account
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Account_iPhone" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"ChangePasswordController"];
    self.account = account;
    
    return self;
}

-(void)changePassword
{
    [self.account changeOldPassword:self.currentPasswordInputField.text
                             toNewPassword:self.passwordInputField.text
                          onPasswordChange:^(BOOL passwordChangeSuccessful, NSError *error) {
                              
                              if(passwordChangeSuccessful)
                              {
                                  [self.delegate didChangePassword];
                              }
                          }];
}


- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.currentPasswordInputField)
    {
        [self.passwordInputField becomeFirstResponder];
    }
    
    if(textField == self.passwordInputField)
    {
        [textField resignFirstResponder];
        [self changePassword];
    }
    return YES;
}


@end
