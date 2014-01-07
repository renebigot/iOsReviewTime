//
//  BRAppCell.m
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRAppCell.h"

@implementation BRAppCell

- (void)downloadIconFromURL:(NSString *)appIconURL {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appIconURL]];
    [NSURLConnection connectionWithRequest:request delegate:self];
    [self.activityIndicator setHidden:NO];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _iconImageData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_iconImageData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    connection = nil;
    _iconImageData = nil;
    
    [[[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    
    [self.activityIndicator setHidden:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    connection = nil;
    [self.appIcon setImage:[UIImage imageWithData:_iconImageData]];
    
    [self.activityIndicator setHidden:YES];
}

@end
