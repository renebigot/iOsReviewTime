//
//  BRAppDelegate.m
//  iRT
//
//  Created by René Bigot on 21/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRAppDelegate.h"
#import "BRRestClient.h"

@implementation BRAppDelegate


- (void)parseTweetsFromJSONData:(NSData *)jsonData {
    NSError *error = nil;
    NSDictionary *resultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
    
    if (error) {
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
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]*) days"
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
    
    [statusMenuItem setTitle:[NSString stringWithFormat:@"iRT : %@ days", averageDaysCount]];
}

-(void)awakeFromNib{
    statusMenuItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusMenuItem setMenu:statusMenu];
    [statusMenuItem setTitle:@"..."];
    [statusMenuItem setHighlightMode:YES];
    

    //Refresh once
    [self refreshTweets];
    

    //Then, refresh every 5 minutes
    tweetsTimer = [NSTimer scheduledTimerWithTimeInterval:5*60
                                                   target:self
                                                 selector:@selector(refreshTweets)
                                                 userInfo:nil
                                                  repeats:YES];

    
}

- (void)refreshTweets {
    _tweetsCount = [NSDecimalNumber zero];
    
    NSURL *twitterDotCom = [NSURL URLWithString:@"http://search.twitter.com"];
    NSString *tweetsURL = @"/search.json?q=iosreviewtime&rpp=100";
    
    BRRestClient *restClient = [[BRRestClient alloc] init];
    [restClient setBaseURL:twitterDotCom];
    [restClient read:tweetsURL withCompletionBlock:^{
        [self parseTweetsFromJSONData:[restClient rawServerResponse]];
    }];

}

@end
