//
//  BRTweetCell.h
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRTweetCell : UITableViewCell {
    NSMutableData *_avatarImageData;
}

- (void)downloadAvatar:(NSURL *)imageUrl;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *tweetAvatar;
@property (nonatomic, strong) IBOutlet UILabel *tweetUser;
@property (nonatomic, strong) IBOutlet UILabel *tweetUserName;
@property (nonatomic, strong) IBOutlet UILabel *tweetText;
@property (nonatomic, strong) NSURL *tweetUrl;


@end
