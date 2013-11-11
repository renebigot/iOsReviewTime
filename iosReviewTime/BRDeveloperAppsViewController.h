//
//  BRDeveloperAppsViewController.h
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRDeveloperAppsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIBarPositioningDelegate> {
    NSString *_developerName;
    NSMutableArray *_tableViewCells;
    
    NSString *_itcUsername;
    NSString *_itcPassword;
    
    IBOutlet UIActivityIndicatorView *_activityIndicator;
    IBOutlet UITableView *_tableview;
}

- (IBAction)refreshApps:(id)sender;
- (IBAction)login:(id)sender;

@end
