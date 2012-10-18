//
//  BRAppCell.h
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRAppCell : UITableViewCell {
    NSMutableData *_iconImageData;
}

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *appIcon;
@property (nonatomic, strong) IBOutlet UILabel *appName;
@property (nonatomic, strong) NSURL *appURL;

- (void)downloadIcon:(NSString *)appID;

@end
