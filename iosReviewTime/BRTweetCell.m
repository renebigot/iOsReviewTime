//
//  BRTweetCell.m
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRTweetCell.h"

@implementation BRTweetCell

- (void)downloadAvatar:(NSURL *)avatarURL {
    NSURLRequest *request = [NSURLRequest requestWithURL:avatarURL];
    [NSURLConnection connectionWithRequest:request delegate:self];
    
    [_activityIndicator setHidden:NO];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _avatarImageData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_avatarImageData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    connection = nil;
    _avatarImageData = nil;
    
    [[[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    [_activityIndicator setHidden:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    connection = nil;
    [self.tweetAvatar setImage:[UIImage imageWithData:_avatarImageData]];

    [_activityIndicator setHidden:YES];
}

@end
