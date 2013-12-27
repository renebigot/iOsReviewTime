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
    
    // Set the badge to display the correct setting
    [self.appBadgeSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"badgeCount"] animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)appBadgeSettingChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.appBadgeSwitch.isOn forKey:@"badgeCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)contact:(id)sender {
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    [mailComposer setMailComposeDelegate:self];
    [mailComposer setToRecipients:@[@"contact@iraremedia.com"]];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    [mailComposer setMessageBody:[NSString stringWithFormat:@"<br /><br /><hr /><p style=\"color:grey;font-family:helvetica\">This technical information helps us help you. Include it if you need support or are reporting a bug.<br />Version %@ (%@)<br />iOS Version: %@</p><hr />", majorVersion, minorVersion, [UIDevice currentDevice].systemVersion] isHTML:YES];
    
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
    [[[UIAlertView alloc] initWithTitle:@"iOS Review Time" message:version delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", @"Alert Popup Button") otherButtonTitles:nil] show];
}

- (NSString *)appNameAndVersionNumberDisplayString {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"Version %@ (build %@). Updated on December 27, 2013.", majorVersion, minorVersion];
}

@end
