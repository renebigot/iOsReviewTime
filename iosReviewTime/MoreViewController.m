//
//  MoreViewController.m
//  iOS Review Time
//
//  Created by iRare Media on 12/27/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "MoreViewController.h"

@interface MoreViewController ()

@end

@implementation MoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Get User Defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Set the badge to display the correct setting
    [self.appBadgeSwitch setOn:[defaults boolForKey:@"badgeCount"] animated:YES];
    
    // Set the segment to show the correct setting
    [self.dateRangeSegment setSelectedSegmentIndex:[self getIndexFromSeconds:[defaults integerForKey:@"dateRange"]]];
    
    // Set the slider to show the correct setting
    int numberOfTweets = (int)[defaults integerForKey:@"tweetNumber"];
    [self.tweetSlider setValue:numberOfTweets animated:YES];
    [self.numberOfTweetsLabel setText:[NSString stringWithFormat:@"%i tweets", numberOfTweets]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)appBadgeSettingChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.appBadgeSwitch.isOn forKey:@"badgeCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)dateRangeDidChange:(id)sender {
    /* Four Segements to choose:
     0. 24 Hours = 86400 Seconds
     1. 5 Days = 432000 Seconds
     2. 7 Days = 604800 Seconds
     3. 14 Days = 1209600 Seconds !! Twitter API only returns up to 9 days back !! */
    
    // Get the selected segment number
    NSInteger selectedSegement = self.dateRangeSegment.selectedSegmentIndex;
    
    // Save the appropriate number of seconds based on the selected segment
    if (selectedSegement == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:ONE_DAY_IN_SECONDS forKey:@"dateRange"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (selectedSegement == 1) {
        [[NSUserDefaults standardUserDefaults] setInteger:FIVE_DAYS_IN_SECONDS forKey:@"dateRange"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (selectedSegement == 2) {
        [[NSUserDefaults standardUserDefaults] setInteger:SEVEN_DAYS_IN_SECONDS forKey:@"dateRange"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSInteger)getIndexFromSeconds:(NSInteger)seconds {
    if (seconds == ONE_DAY_IN_SECONDS) {
        return 0;
    } else if (seconds == FIVE_DAYS_IN_SECONDS) {
        return 1;
    } else if (seconds == SEVEN_DAYS_IN_SECONDS) {
        return 2;
    } else return 2;
}

- (IBAction)tweetNumberIsChanging:(id)sender {
    self.numberOfTweetsLabel.text = [NSString stringWithFormat:@"%i tweets", (int)self.tweetSlider.value];
}

- (IBAction)tweetNumberDidChange:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:(int)self.tweetSlider.value forKey:@"tweetNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)contact:(id)sender {
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    [mailComposer setMailComposeDelegate:self];
    [mailComposer setToRecipients:@[@"rene.bigot@brae.fr"]];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    [mailComposer setMessageBody:[NSString stringWithFormat:@"<br /><br /><hr /><p style=\"color:grey;font-family:helvetica\">%@<br />Version %@ (%@)<br />iOS Version: %@</p><hr />",
                                  NSLocalizedString(@"This technical information helps us help you. Include it if you need support or are reporting a bug.", nil),
                                  majorVersion,
                                  minorVersion,
                                  [UIDevice currentDevice].systemVersion] isHTML:YES];
    
    [self presentViewController:mailComposer animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)viewWebsite {
    NSURL *url = [[NSURL alloc] initWithString:@"http://www.github.com/renebigot/iOsReviewTime"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)viewSupport {
    NSURL *url = [[NSURL alloc] initWithString:@"http://www.github.com/renebigot/iOsReviewTime/issues"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)viewVersionInfo {
    NSString *version = [self appNameAndVersionNumberDisplayString];
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"iOS Review Time", nil)
                                message:version
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Alert Popup Button")
                      otherButtonTitles:nil] show];
}

- (NSString *)appNameAndVersionNumberDisplayString {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:NSLocalizedString(@"Version %@ (build %@).\nUpdated on January 1, 2014.", nil), majorVersion, minorVersion];
}

@end
