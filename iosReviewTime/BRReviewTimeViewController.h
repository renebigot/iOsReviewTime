//
//  BRReviewTimeViewController.h
//  iosReviewTime
//
//  Created by René Bigot on 14/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface BRReviewTimeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIBarPositioningDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *requestData;
@property (strong, nonatomic) NSURL *apiURL;
@property (nonatomic, strong) NSMutableArray *results;

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
