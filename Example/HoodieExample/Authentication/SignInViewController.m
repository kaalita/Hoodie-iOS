//
// Created by Katrin Apel on 03/03/14.
// Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "SignInViewController.h"
#import "HOOHoodie.h"
#import "SignUpViewController.h"

@interface SignInViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameInputField;
@property (weak, nonatomic) IBOutlet UITextField *passwordInputField;

@end

@implementation SignInViewController

- (id)initWithHoodie:(HOOHoodie *)hoodie
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Authentication_iPhone" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
    self.hoodie = hoodie;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"signInToSignUp"])
    {
        SignUpViewController *signUpViewController = segue.destinationViewController;
        signUpViewController.authenticationDelegate = self.authenticationDelegate;
        signUpViewController.hoodie = self.hoodie;
    }
}

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

        [self signInUser];
    }
    return YES;
}

- (void)signInUser
{
    [self.hoodie.account signInUserWithName:self.usernameInputField.text
                                   password:self.passwordInputField.text
                                   onSignIn:^(BOOL signInSuccessful, NSError *error) {
                                       if(signInSuccessful)
                                       {
                                           [self.authenticationDelegate userDidSignIn];
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