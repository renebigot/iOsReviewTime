//
//  BRAppCell.m
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRAppCell.h"
#import "BRRestClient.h"

@implementation BRAppCell

- (void)downloadIcon:(NSString *)appID {
    NSURL *ituneApi = [NSURL URLWithString:@"http://itunes.apple.com"];
    NSString *searchURI = [NSString stringWithFormat:@"/lookup?id=%@", appID];
    
    BRRestClient *restClient = [[BRRestClient alloc] init];
    [restClient setBaseURL:ituneApi];
    [restClient read:searchURI withCompletionBlock:^{
        NSError *error;
        NSDictionary *dictFromJSON = [NSJSONSerialization JSONObjectWithData:[restClient rawServerResponse]
                                                                   options:NSJSONReadingAllowFragments error:&error];
        
        if (error) {
            self.appIcon = nil;
            [self.activityIndicator setHidden:YES];
            return ;
        }
        
        NSArray *resultArray = [dictFromJSON objectForKey:@"results"];
        if ([resultArray count]) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[resultArray objectAtIndex:0] objectForKey:@"artworkUrl512"]]];
            [NSURLConnection connectionWithRequest:request delegate:self];
            [self.activityIndicator setHidden:NO];
        } else {
            [self.activityIndicator setHidden:YES];
        }
    }];
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
    
    [[[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                message:[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
    
    [self.activityIndicator setHidden:YES];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Succeeded! Received %d bytes of data",[_iconImageData length]);
    
    connection = nil;
    [self.appIcon setImage:[UIImage imageWithData:_iconImageData]];
    
    [self.activityIndicator setHidden:YES];
}


@end
