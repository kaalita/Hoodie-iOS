//
//  PlaygroundViewController.m
//  HoodiePlayground
//
//  Created by Katrin Apel on 22/02/14.
//  Copyright (c) 2014 Hoodie. All rights reserved.
//

#import "PlaygroundViewController.h"
#import "PlaygroundCell.h"
#import "PlaygroundDataSource.h"
#import "HOOStore.h"
#import "SignInViewController.h"
#import "HOOHoodie.h"
#import "SVProgressHUD.h"

@interface PlaygroundViewController ()  <UITableViewDelegate,UITextFieldDelegate,AuthenticationDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userGreeting;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *inputField;
@property (strong, nonatomic) HOOHoodie *hoodie;
@property (strong, nonatomic) PlaygroundDataSource *dataSource;

@end

@implementation PlaygroundViewController

- (id)initWithHoodie:(HOOHoodie *)hoodie
{
    self = [self initWithNibName:@"PlaygroundViewController" bundle:nil];

    self.hoodie = hoodie;

    TableViewCellConfigureBlock configureCell = ^(PlaygroundCell *cell, NSDictionary *dictionary) {
        [cell configureForTodoItem:dictionary];
    };

    self.dataSource = [[PlaygroundDataSource alloc] initWithStore:self.hoodie.store
                                                   cellIdentifier:[PlaygroundCell cellIdentifier]
                                               cellConfigureBlock:configureCell];


    NSNotificationCenter*notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(storeChanged:)
                               name:HOOStoreChangeNotification
                             object:nil];

    return self;
}

- (void) storeChanged: (NSNotification *)notification
{

    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[PlaygroundCell nib] forCellReuseIdentifier:[PlaygroundCell cellIdentifier]];
    self.tableView.dataSource = self.dataSource;

    self.navigationItem.title = @"Hoodie";

    [SVProgressHUD showWithStatus:@"Loading" maskType:SVProgressHUDMaskTypeBlack];

    [self.hoodie.account automaticallySignInExistingUser:^(BOOL existingUser, NSError *error) {
        
        [SVProgressHUD dismiss];
        [self updateSignInStateDependentElements];
    }];
}

- (void)updateSignInStateDependentElements
{
    if(self.hoodie.account.authenticated)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign out"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(signOut)];

        self.userGreeting.text = [NSString stringWithFormat:@"%@ %@",
                                                            NSLocalizedString(@"Hello", nil),
                                                            self.hoodie.account.username];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sign In"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(signIn)];

        self.userGreeting.text = NSLocalizedString(@"Not signed in", nil);
    }
}

- (void)signIn
{
    SignInViewController *signInViewController = [[SignInViewController alloc] initWithHoodie:self.hoodie];
    signInViewController.authenticationDelegate = self;

    UINavigationController *signInNavigationController = [[UINavigationController alloc] initWithRootViewController:signInViewController];
    [self presentViewController:signInNavigationController animated:YES completion:^{
        
    }];
}

- (void)signOut
{
    [self.hoodie.account signOutOnFinished:^(BOOL signOutSuccessful, NSError *error) {
        [self updateSignInStateDependentElements];
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlaygroundCell *selectedCell = (PlaygroundCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    [selectedCell showEditingMode:YES];
    selectedCell.textField.tag = indexPath.row;
    selectedCell.textField.delegate = self;
    [selectedCell.textField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.inputField)
    {
        if([textField.text isEqualToString:@""])
        {
            [textField resignFirstResponder];
        }
        else
        {
            NSDictionary *newTodo = @{@"title": textField.text};
            [self.hoodie.store saveObject:newTodo
                                 withType:@"todo"
                                   onSave:^(NSDictionary *object, NSError *error) {
                                        if(error)
                                        {
                                            NSLog(@"Error saving object: %@", error);
                                        }
            }];

            [textField resignFirstResponder];
            textField.text = @"";
        }
    }
    else
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:textField.tag inSection:0];
        PlaygroundCell *cell = (PlaygroundCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [self.hoodie.store updateObjectWithId:cell.todoItem[@"id"]
                                      andType:cell.todoItem[@"type"]
                               withProperties:@{@"title": textField.text} onUpdate:^(BOOL updateSuccessful, NSError *error) {
                                   
                                   [textField resignFirstResponder];
                                   [cell showEditingMode:NO];
                                   if(error)
                                   {
                                       NSLog(@"Error updating object: %@", [error localizedDescription]);
                                   }
                               }];
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:textField.tag inSection:0];
    PlaygroundCell *cell = (PlaygroundCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell showEditingMode:NO];
}


#pragma mark - AuthenticationDelegate

- (void)userDidSignIn
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self updateSignInStateDependentElements];
    }];
}

- (void)userDidSignUp
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self updateSignInStateDependentElements];
    }];
}

@end
