//
//  MoreViewController.h
//  iOS Review Time
//
//  Created by iRare Media on 12/27/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "FDKeychain.h"
#define PRODUCT_ID @"com.ReviewTime.BackgroundFetch"

static const NSInteger ONE_DAY_IN_SECONDS = 86400;
static const NSInteger FIVE_DAYS_IN_SECONDS = 432000;
static const NSInteger SEVEN_DAYS_IN_SECONDS = 604800;

@interface MoreViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *appBadgeSwitch;
- (IBAction)appBadgeSettingChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *dateRangeSegment;
- (IBAction)dateRangeDidChange:(id)sender;

@property (weak, nonatomic) IBOutlet UISlider *tweetSlider;
@property (weak, nonatomic) IBOutlet UILabel *numberOfTweetsLabel;
- (IBAction)tweetNumberIsChanging:(id)sender;
- (IBAction)tweetNumberDidChange:(id)sender;

- (IBAction)contact:(id)sender;
- (IBAction)viewWebsite;
- (IBAction)viewSupport;
- (IBAction)viewVersionInfo;

@property (weak, nonatomic) IBOutlet UITableViewCell *fetchNotPurchasedCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *fetchPurchasedCell;

@end
