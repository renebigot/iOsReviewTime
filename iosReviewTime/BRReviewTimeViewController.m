//
//  BRReviewTimeViewController.m
//  iosReviewTime
//
//  Created by René Bigot on 14/10/12.
//  Copyright (c) 2012 René Bigot. Copyright (c) 2013 iRare Media. All rights reserved.
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
    return [NSString stringWithFormat:@"%i #iOSReviewTime Tweets", (int)[tableViewCells count]];
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
        NSDictionary *parameters = @{@"q":@"#iosreviewtime", @"count":[NSString stringWithFormat:@"%i", (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"tweetNumber"]], @"result_type":@"recent"};
        NSLog(@"Tweets to gather: %@", [parameters objectForKey:@"count"]);
        
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

- (NSString *)getTimeStringFromSeconds:(NSInteger)seconds {
    if (seconds == ONE_DAY_IN_SECONDS) {
        return @"day";
    } else if (seconds == FIVE_DAYS_IN_SECONDS) {
        return @"5 days";
    } else if (seconds == SEVEN_DAYS_IN_SECONDS) {
        return @"7 days";
    } else return @"7 days";
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
        
        // Parse the downloaded tweets - these will be displayed and an average will be calculated
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
                // Check to see if iTunes Connect is shutdown for the holidays
                if ([self date:[NSDate date] isBetweenDate:[NSDate dateWithMonth:12 day:22] andDate:[NSDate dateWithMonth:12 day:26]]) {
                    // iTunes Connect is shutdown, hide the app badge no matter what the user's setting is, and then display a warning about innaccuracy. The warning message is more detailed on the iPad becuase there is more space
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                    
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) [statusLabel setText:NSLocalizedString(@"iTunes Connect is Shutdown for the Winter Holiday until December 28. Review Times for this week may be inaccurate.", @"iPad Warning for iTC Holiday Shutdown")];
                    else [statusLabel setText:NSLocalizedString(@"iTC is shutdown until Dec 28. Review Times may be inaccurate.", @"iPhone Warning for iTC Holiday Shutdown")];
                    
                } else {
                    // iTC is not shutdown for the winter holiday, just display the default text
                    NSString *time = [self getTimeStringFromSeconds:[[NSUserDefaults standardUserDefaults] integerForKey:@"dateRange"]];
                    [statusLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Average review time for the last %@", @"Status Text"), time]];
                }
                
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
    [tableview setContentInset:UIEdgeInsetsMake(0., 0., 50., 0.)];
    [tableview setScrollIndicatorInsets:UIEdgeInsetsMake(0., 0., 50., 0.)];
    [tableview flashScrollIndicators];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [statusLabel setText:NSLocalizedString(@"Failed to Reach Twitter", @"Status Text")];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.connection = nil;
    self.requestData = nil;
    
    [tableview reloadData];
    [tableview setScrollIndicatorInsets:UIEdgeInsetsMake(0., 0., 50., 0.)];
    [tableview setContentInset:UIEdgeInsetsMake(0., 0., 50., 0.)];
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
    
    NSInteger timeInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"dateRange"];
    if (!timeInterval) timeInterval = 604800;
    
    NSDate *lastWeek = [[NSDate date] dateByAddingTimeInterval:-timeInterval];
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
                            cell.tweetUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@/statuses/%@", [tweet objectForKey:@"screen_name"], [tweet objectForKey:@"id_str"]]];
                            
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"badgeCount"] == YES) {
        //Average rounded to the nearest integer
        NSInteger average = [averageDaysCount floatValue] + .5;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:average];
    } else {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
    
    [tableview reloadData];
    [tableview setContentInset:UIEdgeInsetsMake(0., 0., 50., 0.)];
    [tableview setScrollIndicatorInsets:UIEdgeInsetsMake(0., 0., 50., 0.)];
    
    if (error) {
        completionBlock(error);
        return;
    } else {
        completionBlock(nil);
        return;
    }
}

- (BOOL)date:(NSDate *)date isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate {
    if ([date compare:beginDate] == NSOrderedAscending) return NO;
    
    if ([date compare:endDate] == NSOrderedDescending) return NO;
    
    return YES;
}

@end
