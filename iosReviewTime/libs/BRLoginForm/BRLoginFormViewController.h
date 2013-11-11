//
//  BRLoginFormViewController.h
//  iosReviewTime
//
//  Created by René Bigot on 18/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRLoginFormViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIBarPositioningDelegate> {
    UITextField *_passwordField;
    UITextField *_usernameField;

    __block void (^_loginCompletionBlock)(void);
}

+ (NSString *)username;
+ (NSString *)password;
- (void)setCompletionBlock:(void (^)(void))completionBlock;
- (IBAction)dismissLoginForm:(id)sender;

@property (nonatomic, strong) NSString *loginFormTitle;
@property (nonatomic, strong) NSString *loginFormFooterNote;

@end
