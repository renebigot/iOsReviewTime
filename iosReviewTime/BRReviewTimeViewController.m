//
//  BRReviewTimeViewController.m
//  iosReviewTime
//
//  Created by René Bigot on 14/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRReviewTimeViewController.h"
#import "BRRestClient.h"
#import "BRTweetCell.h"

@interface BRReviewTimeViewController ()

@end

@implementation BRReviewTimeViewController

- (void)parseTweetsFromJSONData:(NSData *)jsonData {
    NSError *error = nil;
    NSDictionary *resultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
    
    if (error) {
        [[[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                   message:[error localizedFailureReason]
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil] show];
        return;
    }
    
    NSArray *tweets = [resultsDict objectForKey:@"results"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"EEE, d LLL yyyy HH:mm:ss Z"];

    NSDate *yesterday = [[NSDate date] dateByAddingTimeInterval:-24 * 60 * 60];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]*) day"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    NSDecimalNumber *averageDaysCount = [NSDecimalNumber zero];

    for (NSDictionary *tweet in tweets) {
        NSDate *tweetDate = [dateFormatter dateFromString:[tweet objectForKey:@"created_at"]];
        if ([tweetDate compare:yesterday] == NSOrderedDescending) {
            NSString *tweetText = [tweet objectForKey:@"text"];

            NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:tweetText
                                                                 options:0
                                                                   range:NSMakeRange(0, [tweetText length])];
            if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
                if (![[tweet objectForKey:@"from_user"] isEqualToString:@"appreviewtimes"]) {
                    NSString *substringForFirstMatch = [tweetText substringWithRange:rangeOfFirstMatch];
                    NSDecimalNumber *daysCount = [NSDecimalNumber decimalNumberWithString:substringForFirstMatch];
                    NSLog(@"Dayscount : %@", daysCount);

                    if (![daysCount isEqual:[NSDecimalNumber notANumber]]) {
                        averageDaysCount = [averageDaysCount decimalNumberByAdding:daysCount];
                        
                        NSLog(@"%@ : %@", tweetDate, tweetText);
                        _tweetsCount = [_tweetsCount decimalNumberByAdding:[NSDecimalNumber one]];
                        
                        NSArray* nib = [[NSBundle mainBundle] loadNibNamed:@"BRReviewTimeViewController" owner:self options:nil];
                        BRTweetCell *cell = (BRTweetCell *)[nib objectAtIndex:1];
                        
                        cell.tweetUser.text = [NSString stringWithFormat:@" @%@", [tweet objectForKey:@"from_user"]];
                        cell.tweetUserName.text = [tweet objectForKey:@"from_user_name"];
                        [cell.tweetUser sizeToFit];
                        [cell.tweetUserName sizeToFit];
                        [cell.tweetUser setFrame:CGRectMake(cell.tweetUserName.frame.origin.x + cell.tweetUserName.frame.size.width,
                                                            cell.tweetUser.frame.origin.y,
                                                            cell.tweetUser.frame.size.width, cell.tweetUser.frame.size.height)];
                        cell.tweetText.text = [tweet objectForKey:@"text"];
                        cell.tweetUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@/%@",
                                                              [tweet objectForKey:@"from_user"],
                                                              [tweet objectForKey:@"id_str"]]];
                        NSURL *imageUrl = [NSURL URLWithString:[tweet objectForKey:@"profile_image_url"]];
                        [cell downloadAvatar:imageUrl];
                        
                        [_tableViewCells addObject:cell];
                    }
                }
            }
        }
    }
    NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                                      scale:2
                                                                                           raiseOnExactness:NO
                                                                                            raiseOnOverflow:NO
                                                                                           raiseOnUnderflow:NO
                                                                                        raiseOnDivideByZero:NO];
    averageDaysCount = [averageDaysCount decimalNumberByDividingBy:_tweetsCount withBehavior:roundingBehavior];
    
    [_reviewTimeLabel setText:[NSString stringWithFormat:@"%@ days", averageDaysCount]];
    
    [_tableview reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshTweets:nil];
}

#pragma mark - UITableView delegate & data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BRTweetCell *currentCell = [_tableViewCells objectAtIndex:indexPath.row];
    CGSize detailTextSize = [currentCell.tweetText.text
                             sizeWithFont:[[currentCell tweetText] font]
                             constrainedToSize:CGSizeMake(currentCell.tweetText.frame.size.width, 1000)
                             lineBreakMode:currentCell.detailTextLabel.lineBreakMode];
    [[currentCell tweetText] setFrame:CGRectMake(currentCell.tweetText.frame.origin.x,
                                                 currentCell.tweetText.frame.origin.y,
                                                 detailTextSize.width, detailTextSize.height)];
    [currentCell setFrame:CGRectMake(0, 0, detailTextSize.width, currentCell.tweetText.frame.origin.y + detailTextSize.height + 3)];
    

    return currentCell.frame.size.height;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableViewCells count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Extracted from those tweets";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_tableViewCells objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[UIApplication sharedApplication] openURL:[[_tableViewCells objectAtIndex:indexPath.row] tweetUrl]];
}

#pragma mark - IBActions

- (IBAction)refreshTweets:(id)sender {
    _tweetsCount = [NSDecimalNumber zero];
    _tableViewCells = [[NSMutableArray alloc] init];
    
    [_activityIndicator setHidden:NO];
    [_activityIndicator startAnimating];
    [_reviewTimeLabel setHidden:YES];
    [_reviewTimeLabel setText:@"..."];
    
    NSURL *twitterDotCom = [NSURL URLWithString:@"http://search.twitter.com"];
    NSString *tweetsURL = @"/search.json?q=iosreviewtime&rpp=100";
    
    BRRestClient *restClient = [[BRRestClient alloc] init];
    [restClient setBaseURL:twitterDotCom];
    [restClient read:tweetsURL withCompletionBlock:^{
        [self parseTweetsFromJSONData:[restClient rawServerResponse]];
        [_activityIndicator stopAnimating];
        [_activityIndicator setHidden:YES];
        [_reviewTimeLabel setHidden:NO];
    }];
}



@end
