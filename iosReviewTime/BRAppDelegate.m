//
//  BRAppDelegate.m
//  iOSReviewTime
//
//  Created by iRare Media on 12/26/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "BRAppDelegate.h"

@interface BRAppDelegate () {
    ACAccountStore *accountStore;
    NSURLConnection *connection;
    NSURL *apiURL;
    
    NSMutableData *requestData;
    NSMutableArray *results;
    
    NSDecimalNumber *tweetsCount;
    int reviewTime;
}
@end

@implementation BRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set the Background Fetch Interval to 24 Hours - This means that iOS will only attempt to fetch data once daily
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:86400];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Get Review Time data from Twitter
    [self updateReviewTimeWithCompletion:^(NSError *error) {
        if (error) {
            // Let UIApplication know that we've finished the background refresh
            completionHandler(UIBackgroundFetchResultFailed);
            
            // Log the Background Refresh
            NSLog(@"iOS Review Time: Background Fetch failed");
        } else {
            // Cancel all local notifications that have already been delivered
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            
            // Deliver a notification about the review time
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = [NSString stringWithFormat:@"Current iOS Review Time is %i days.", reviewTime];
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"badgeCount"] == YES)  localNotification.applicationIconBadgeNumber = reviewTime;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            
            // Let UIApplication know that we've finished the background refresh
            completionHandler(UIBackgroundFetchResultNewData);
            
            // Log the Background Refresh
            NSLog(@"iOS Review Time: Background Fetch completed");
        }
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Parsing Tweets

- (void)updateReviewTimeWithCompletion:(void (^)(NSError *error))completionHandler {
    // Set our API URL - 1.1 of the Twitter REST API
    if (!apiURL) apiURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];
    
    // Grab the system's account store, and check if we have a twitter account associated with the device
    if (!accountStore) accountStore = [[ACAccountStore alloc] init];
    
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) return;
    
    ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // Authenticate the account
    [accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
        // Create search parameters
        NSDictionary *parameters = @{@"q":@"iosreviewtime", @"count":@"100", @"result_type":@"mixed"};
        
        // Request results from the Twitter API
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[apiURL URLByAppendingPathComponent:@"search/tweets.json"] parameters:parameters];
        
        // Use the last Twitter account
        NSArray *twitterAccounts = [accountStore accountsWithAccountType:twitterAccountType];
        request.account = twitterAccounts.lastObject;
        
        [[NSURLSession sharedSession] dataTaskWithRequest:[request preparedURLRequest] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Check for returned data
            if (!data) return;
            
            // Get the returned JSON object
            NSError *jsonError;
            NSDictionary *requestDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) return;
            
            // Set the results
            results = requestDictionary[@"statuses"];
            
            // Setup a Date Formatter to filter tweets by date
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            [dateFormatter setLocale:usLocale];
            [dateFormatter setDateStyle:NSDateFormatterLongStyle];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:@"EEE, d LLL yyyy HH:mm:ss Z"];
            
            NSDate *lastWeek = [[NSDate date] dateByAddingTimeInterval:-604800];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]*) day" options:NSRegularExpressionCaseInsensitive error:&error];
            NSDecimalNumber *averageDaysCount = [NSDecimalNumber zero];
            
            if (error) return;
            
            for (NSDictionary *tweet in results) {
                NSDate *tweetDate = [dateFormatter dateFromString:[tweet objectForKey:@"created_at"]];
                if ([tweetDate compare:lastWeek] <= NSOrderedDescending) {
                    NSString *tweetText = [tweet objectForKey:@"text"];
                    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:tweetText options:0 range:NSMakeRange(0, [tweetText length])];
                    
                    if ((!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) && (![[tweet objectForKey:@"from_user"] isEqualToString:@"appreviewtimes"])) {
                        @try {
                            NSString *substringForFirstMatch = [tweetText substringWithRange:rangeOfFirstMatch];
                            NSDecimalNumber *daysCount = [NSDecimalNumber decimalNumberWithString:substringForFirstMatch];
                            
                            if (![daysCount isEqual:[NSDecimalNumber notANumber]]) {
                                averageDaysCount = [averageDaysCount decimalNumberByAdding:daysCount];
                                
                                tweetsCount = [tweetsCount decimalNumberByAdding:[NSDecimalNumber one]];
                            }
                        } @catch (NSException *exception) {
                            NSLog(@"Caught Exception\n\n%@\n", exception);
                        }
                    }
                }
            }
            
            NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:2 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
            averageDaysCount = [averageDaysCount decimalNumberByDividingBy:tweetsCount withBehavior:roundingBehavior];
            
            reviewTime = [averageDaysCount intValue];
            
            if (error) {
                completionHandler(error);
                return;
            } else {
                completionHandler(nil);
                return;
            }
        }];
    }];
}

@end
