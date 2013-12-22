//
//  BRAppDelegate.m
//  iRT
//
//  Created by René Bigot on 21/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRAppDelegate.h"

@implementation BRAppDelegate
@synthesize accountStore, connection, requestData, apiURL, results, tweetsCount;

#pragma mark - Lifecycle

- (void)awakeFromNib {
    statusMenuItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusMenuItem setMenu:statusMenu];
    [statusMenuItem setTitle:@"Loading"];
    [statusMenuItem setHighlightMode:YES];
    
    // Set our API URL - 1.1 of the Twitter REST API
    if (!apiURL) apiURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];
    
    // Grab the system's account store
    if (!accountStore) accountStore = [[ACAccountStore alloc] init];
    
    // Check for Twitter Access
    [self hasTwitterAccess:^(BOOL hasAcces) {
        if (hasAcces) [self refreshTweets];
        else [self displayNoTwitterError];
    }];
    
    // Refresh once
    [self refreshTweets];
    
    // Then, refresh every 5 minutes
    tweetsTimer = [NSTimer scheduledTimerWithTimeInterval:5*60 target:self selector:@selector(refreshTweets) userInfo:nil repeats:YES];
}

#pragma mark - Tweet Parsing

- (void)hasTwitterAccess:(void (^)(BOOL hasAcces))completionBlock {
    ACAccountType *accType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted && error == nil) {
            completionBlock(YES);
        } else {
            completionBlock(NO);
            NSLog(@"Error: %@", [error description]);
            NSLog(@"Access denied");
        }
    }];
}

- (void)displayNoTwitterError {
    [statusMenuItem setTitle:@"No Twitter"];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"No Twitter Accounts"];
    [alert setInformativeText:@"There are no Twitter accounts configured. You can add or create a Twitter account in System Preferences."];
    [alert addButtonWithTitle:@"Okay"];
    
    [alert runModal];
}

- (void)refreshTweets {
    // Check for Twitter Access
    [self hasTwitterAccess:^(BOOL hasAcces) {
        if (!hasAcces) {
            [self displayNoTwitterError];
            return;
        }
    }];
    
    tweetsCount = [NSDecimalNumber zero];
    
    ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    // Authenticate the account
    [self.accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
        // Create search parameters
        NSDictionary *parameters = @{@"q":@"iosreviewtime", @"count":@"50", @"result_type":@"mixed"};
        apiURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/"];
        
        // Request results from the Twitter API
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[self.apiURL URLByAppendingPathComponent:@"search/tweets.json"] parameters:parameters];
        
        // Use the last Twitter account
        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:twitterAccountType];
        request.account = twitterAccounts.lastObject;
        
        // Disptach on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connection = [[NSURLConnection alloc] initWithRequest:[request preparedURLRequest] delegate:self];
        });
    }];
    
}

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
            
            if (NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
                if (![[tweet objectForKey:@"from_user"] isEqualToString:@"appreviewtimes"]) {

                        NSString *substringForFirstMatch = [tweetText substringWithRange:rangeOfFirstMatch];
                        NSDecimalNumber *daysCount = [NSDecimalNumber decimalNumberWithString:substringForFirstMatch];
                        
                        if (![daysCount isEqual:[NSDecimalNumber notANumber]]) {
                            averageDaysCount = [averageDaysCount decimalNumberByAdding:daysCount];
                            
                            tweetsCount = [tweetsCount decimalNumberByAdding:[NSDecimalNumber one]];
                        }
                }
            }
        }
    }
    
    NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:2 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    averageDaysCount = [averageDaysCount decimalNumberByDividingBy:tweetsCount withBehavior:roundingBehavior];
    
    [statusMenuItem setTitle:[NSString stringWithFormat:@"iOS RT: %@ days", averageDaysCount]];
    
    if (error) {
        completionBlock(error);
        return;
    } else {
        completionBlock(nil);
        return;
    }
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"Response: %@", response);
    requestData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"Data: %@", data);
    [requestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Connection: %@", connection);
    self.connection = nil;
    
    if (self.requestData) {
        NSError *jsonError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.requestData options:NSJSONReadingAllowFragments error:&jsonError];
        if (jsonError) return;
        
        self.results = dict[@"statuses"];
        
        [self parseTweetsFromArray:results completion:^(NSError *error) {
            if (error) {
                NSLog(@"Parsing Error: %@", error);
                [statusMenuItem setTitle:@"Error"];
                return;
            }
        }];
    }
    
    self.requestData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection Error: %@", error);
    [statusMenuItem setTitle:@"Error"];
    
    self.connection = nil;
    self.requestData = nil;
}


@end
