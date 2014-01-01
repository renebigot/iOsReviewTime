//
//  BRReviewTimeViewController.h
//  iosReviewTime
//
//  Created by René Bigot on 14/10/12.
//  Copyright (c) 2012 René Bigot. Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "NSDate+Calendar.h"

static const NSInteger ONE_DAY_IN_SECONDS = 86400;
static const NSInteger FIVE_DAYS_IN_SECONDS = 432000;
static const NSInteger SEVEN_DAYS_IN_SECONDS = 604800;

@interface BRReviewTimeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIBarPositioningDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *requestData;
@property (strong, nonatomic) NSURL *apiURL;
@property (strong, nonatomic) NSMutableArray *results;

@property (strong, nonatomic) NSDecimalNumber *tweetsCount;
@property (strong, nonatomic) NSMutableArray *tableViewCells;

- (BOOL)userHasAccessToTwitter;
- (void)displayNoTwitterError;

- (IBAction)refreshTweets:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *reviewTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end
