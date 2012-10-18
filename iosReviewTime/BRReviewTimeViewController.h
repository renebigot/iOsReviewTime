//
//  BRReviewTimeViewController.h
//  iosReviewTime
//
//  Created by René Bigot on 14/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRReviewTimeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UILabel *_reviewTimeLabel;
    IBOutlet UIActivityIndicatorView *_activityIndicator;
    IBOutlet UITableView *_tableview;
    
    NSDecimalNumber *_tweetsCount;
    NSMutableArray *_tableViewCells;
}

- (IBAction)refreshTweets:(id)sender;

@end
