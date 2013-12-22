//
//  LoginViewController.h
//  iOS Review Time
//
//  Created by iRare Media on 12/21/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "FDKeychain.h"

@protocol LoginViewControllerDelegate <NSObject>
- (void)didLoginUser;
@end

@interface LoginViewController : UIViewController <UITextFieldDelegate, UIBarPositioningDelegate>

- (IBAction)cancel;

@property (weak, nonatomic) id<LoginViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *developerNameField;

@end
