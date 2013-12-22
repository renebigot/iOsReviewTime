//
//  BRReviewTimeViewController.m
//  iosReviewTime
//
//  Created by iRare Media on 14/10/12.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "BRReviewTimeViewController.h"
#import "BRTweetCell.h"

@interface BRReviewTimeViewController ()
@end

@implementation BRReviewTimeViewController
@synthesize reviewTimeLabel, statusLabel, activityIndicator, tableview;
@synthesize accountStore, connection, requestData, apiURL, results;
@synthesize tweetsCount, tableViewCells;

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set our API URL - 1.1 of the Twitter REST API
    if (!apiURL) apiURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];
    
    // Grab the system's account store, and check if we have a twitter account associated with the device
    if (!accountStore) accountStore = [[ACAccountStore alloc] init];
    if (![self userHasAccessToTwitter]) {
        [self displayNoTwitterError];
    } else {
        [self refreshTweets:nil];
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - UITableView Delegate and Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BRTweetCell *currentCell = [tableViewCells objectAtIndex:indexPath.row];
    return currentCell.frame.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableViewCells count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"#iOSReviewTime Tweets";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableViewCells objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[UIApplication sharedApplication] openURL:[[tableViewCells objectAtIndex:indexPath.row] tweetUrl]];
}

#pragma mark - Twitter Content

- (IBAction)refreshTweets:(id)sender {
    if (![self userHasAccessToTwitter]) {
        [self displayNoTwitterError];
        return;
    }
    
    tweetsCount = [NSDecimalNumber zero];
    tableViewCells = [[NSMutableArray alloc] init];
    
    [activityIndicator setHidden:NO];
    [activityIndicator startAnimating];
    [reviewTimeLabel setHidden:YES];
    [reviewTimeLabel setText:NSLocalizedString(@"X days", @"Number of Days Display")];
    [statusLabel setText:NSLocalizedString(@"Authenticating Twitter", @"Status Text")];
    
    ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // Authenticate the account
    [self.accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
        [statusLabel setText:NSLocalizedString(@"Querying Twitter", @"Status Text")];
        
        // Create search parameters
        NSDictionary *parameters = @{@"q":@"iosreviewtime", @"count":@"100", @"result_type":@"mixed"};
        
        // Request results from the Twitter API
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[self.apiURL URLByAppendingPathComponent:@"search/tweets.json"] parameters:parameters];
        
        // Use the last Twitter account
        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:twitterAccountType];
        request.account = twitterAccounts.lastObject;
        
        // Disptach on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [statusLabel setText:NSLocalizedString(@"Connecting Twitter", @"Status Text")];
            self.connection = [[NSURLConnection alloc] initWithRequest:[request preparedURLRequest] delegate:self];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
    }];
}

- (BOOL)userHasAccessToTwitter {
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)displayNoTwitterError {
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    
    [statusLabel setText:NSLocalizedString(@"No Twitter Access. Login in the Settings App", @"Time Display Label")];
    [reviewTimeLabel setText:NSLocalizedString(@"No Twitter", @"Time Display Label")];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Twitter Accounts", @"Alert Title") message:NSLocalizedString(@"There are no Twitter accounts configured. You can add or create a Twitter account in Settings.", @"Alert Message") delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", nil) otherButtonTitles:nil];
    [alert show];
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    requestData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [requestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [statusLabel setText:NSLocalizedString(@"Connected to Twitter", @"Status Text")];
    
    self.connection = nil;
    
    if (self.requestData) {
        [statusLabel setText:NSLocalizedString(@"Downloading Tweets", @"Status Text")];
        NSError *jsonError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.requestData options:NSJSONReadingAllowFragments error:&jsonError];
        if (jsonError) {
            [statusLabel setText:NSLocalizedString(@"Error Parsing Tweets", @"Status Text")];
            return;
        }
        
        self.results = dict[@"statuses"];
        
        [self parseTweetsFromArray:results completion:^(NSError *error) {
            if (error) {
                [statusLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Error Loading Tweets: %ld", nil), (long)error.code]];
                [activityIndicator stopAnimating];
                [activityIndicator setHidden:YES];
                [reviewTimeLabel setText:NSLocalizedString(@"Error", @"Time Display Title")];
                [reviewTimeLabel setHidden:NO];
                [tableview setHidden:YES];
                return;
            } else {
                [statusLabel setText:NSLocalizedString(@"Average review time for last 7 days", @"Status Text")];
                [activityIndicator stopAnimating];
                [activityIndicator setHidden:YES];
                [reviewTimeLabel setHidden:NO];
                [tableview setHidden:NO];
            }
        }];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.requestData = nil;
    
    // Ensure that our table view gets the new data.
    [tableview reloadData];
    [tableview flashScrollIndicators];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [statusLabel setText:NSLocalizedString(@"Failed to Reach Twitter", @"Status Text")];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.connection = nil;
    self.requestData = nil;
    
    [tableview reloadData];
}

#pragma mark - Parsing Tweets

- (void)parseTweetsFromArray:(NSArray *)array completion:(void (^)(NSError *error))completionBlock {
    NSError *error = nil;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"EEE, d LLL yyyy HH:mm:ss Z"];
    
    NSDate *lastWeek = [[NSDate date] dateByAddingTimeInterval:-168 * 60 * 60];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]*) day" options:NSRegularExpressionCaseInsensitive error:&error];
    NSDecimalNumber *averageDaysCount = [NSDecimalNumber zero];
    
    if (error) {
        completionBlock(error);
        return;
    }
    
    for (NSDictionary *tweet in array) {
        NSDate *tweetDate = [dateFormatter dateFromString:[tweet objectForKey:@"created_at"]];
        if ([tweetDate compare:lastWeek] <= NSOrderedDescending) {
            NSString *tweetText = [tweet objectForKey:@"text"];
            
            NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:tweetText options:0 range:NSMakeRange(0, [tweetText length])];
            
            if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
                if (![[tweet objectForKey:@"from_user"] isEqualToString:@"appreviewtimes"]) {
                    @try {
                        NSString *substringForFirstMatch = [tweetText substringWithRange:rangeOfFirstMatch];
                        NSDecimalNumber *daysCount = [NSDecimalNumber decimalNumberWithString:substringForFirstMatch];
                        
                        if (![daysCount isEqual:[NSDecimalNumber notANumber]]) {
                            averageDaysCount = [averageDaysCount decimalNumberByAdding:daysCount];
                            
                            tweetsCount = [tweetsCount decimalNumberByAdding:[NSDecimalNumber one]];
                            
                            static NSString *reuseIdentifier = @"Cell";
                            BRTweetCell *cell = [tableview dequeueReusableCellWithIdentifier:reuseIdentifier];
                            
                            // Get the user data
                            NSDictionary *user = [tweet objectForKey:@"user"];
                            
                            // Get the tweet text, user and URL
                            cell.tweetUser.text = [NSString stringWithFormat:@"%@ @%@", [user objectForKey:@"name"], [user objectForKey:@"screen_name"]];
                            cell.tweetText.text = [tweet objectForKey:@"text"];
                            cell.tweetUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@/%@", [tweet objectForKey:@"from_user"], [tweet objectForKey:@"id_str"]]];
                            
                            // Get the high resolution profile picture
                            [cell downloadAvatar:[NSURL URLWithString:[[user objectForKey:@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""]]];
                            
                            [tableViewCells addObject:cell];
                        }

                    } @catch (NSException *exception) {
                        NSLog(@"Caught Exception\n\n%@\n", exception);
                    }
                }
            }
        }
    }
    
    NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:2 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    averageDaysCount = [averageDaysCount decimalNumberByDividingBy:tweetsCount withBehavior:roundingBehavior];
    
    [reviewTimeLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%@ days", nil), averageDaysCount]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"badgeCount"] == YES) [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[averageDaysCount intValue]];
    else [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    [tableview reloadData];
    
    if (error) {
        completionBlock(error);
        return;
    } else {
        completionBlock(nil);
        return;
    }
}

@end
