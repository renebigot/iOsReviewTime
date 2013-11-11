//
//  BRLoginFormViewController.m
//  iosReviewTime
//
//  Created by René Bigot on 18/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRLoginFormViewController.h"

@interface BRLoginFormViewController ()

@end

@implementation BRLoginFormViewController

+ (NSString *)username {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"login_form_username"];
}

+ (NSString *)password {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"login_form_password"];
}

- (void)viewDidAppear:(BOOL)animated {
    _usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"login_form_username"];
    _passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"login_form_password"];
}

- (void)setCompletionBlock:(void (^)(void))completionBlock {
    _loginCompletionBlock = completionBlock;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.loginFormTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.loginFormFooterNote;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    
    UITextField *textField = nil;
    if (indexPath.row == 0) {
        [titleLabel setText:NSLocalizedString(@"Username", nil)];
        [titleLabel sizeToFit];
        if (!_usernameField) {
            _usernameField = [[UITextField alloc] initWithFrame:CGRectZero];
            [_usernameField setPlaceholder:@"my.name@example.com"];
            [_usernameField setSecureTextEntry:NO];
        }
        textField = _usernameField;
        [textField becomeFirstResponder];
    } else {
        [titleLabel setText:NSLocalizedString(@"Password", nil)];
        [titleLabel sizeToFit];
        if (!_passwordField) {
            _passwordField = [[UITextField alloc] initWithFrame:CGRectZero];
            [_passwordField setPlaceholder:NSLocalizedString(@"Password", nil)];
            [_passwordField setSecureTextEntry:YES];
        }
        textField = _passwordField;
    }
    
    [titleLabel setFrame:CGRectMake(15, 0,
                                    titleLabel.frame.size.width,
                                    [self tableView:tableView heightForRowAtIndexPath:indexPath])];
    [textField sizeToFit];
    [textField setFrame:CGRectMake(5 + titleLabel.frame.origin.x + titleLabel.frame.size.width,
                                   0,
                                   tableView.frame.size.width - (titleLabel.frame.origin.x + titleLabel.frame.size.width + 20),
                                   textField.frame.size.height)];
    
    [textField setDelegate:self];
    [textField setCenter:CGPointMake(textField.center.x, [self tableView:tableView heightForRowAtIndexPath:indexPath] / 2)];

    [_usernameField setKeyboardType:UIKeyboardTypeEmailAddress];
    [_passwordField setKeyboardType:UIKeyboardTypeAlphabet];
    [_usernameField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_passwordField setClearButtonMode:UITextFieldViewModeWhileEditing];
    
    [cell addSubview:titleLabel];
    [cell addSubview:textField];
    
    return cell;
}

- (IBAction)dismissLoginForm:(id)sender {
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self dismissModalViewControllerAnimated:YES];
#pragma clang diagnostic pop
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _usernameField) {
        [_passwordField becomeFirstResponder];
        return YES;
    }
    
    [textField resignFirstResponder];
    
    [[NSUserDefaults standardUserDefaults] setValue:_passwordField.text forKey:@"login_form_password"];
    [[NSUserDefaults standardUserDefaults] setValue:_usernameField.text forKey:@"login_form_username"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    _loginCompletionBlock();
    
    return YES;
}

@end
