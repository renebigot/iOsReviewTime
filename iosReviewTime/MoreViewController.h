//
//  MoreViewController.h
//  iOS Review Time
//
//  Created by iRare Media on 12/27/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface MoreViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *appBadgeSwitch;
- (IBAction)appBadgeSettingChanged:(id)sender;

- (IBAction)contact:(id)sender;
- (IBAction)viewWebsite;
- (IBAction)viewSupport;
- (IBAction)viewVersionInfo;

@end
