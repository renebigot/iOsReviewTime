//
//  DeveloperAppsViewController.h
//  iOSReviewTime
//
//  Created by iRare Media on 12/20/13.
//  Copyright (c) 2012 René Bigot. Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "LoginViewController.h"
#import "BRAppCell.h"

@interface DeveloperAppsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIBarPositioningDelegate, LoginViewControllerDelegate, UIActionSheetDelegate> {
    
    NSString *_developerScreenName;
    NSMutableArray *_developersArray;
}

@property (strong, nonatomic) NSString *developerNameOrId;
@property (strong, nonatomic) NSDictionary *dictionaryData;
@property (strong, nonatomic) NSMutableArray *tableViewCells;
@property (strong, nonatomic) NSMutableArray *appURLs;

@property (weak, nonatomic) LoginViewController *loginView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginButton;

- (IBAction)refreshApps;
- (IBAction)login;

@end
