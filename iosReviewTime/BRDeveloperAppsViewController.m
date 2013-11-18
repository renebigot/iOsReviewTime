//
//  BRDeveloperAppsViewController.m
//  iosReviewTime
//
//  Created by René Bigot on 15/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRDeveloperAppsViewController.h"
#import "BRRestClient.h"
#import "BRAppCell.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import "BRLoginFormViewController.h"

@implementation BRDeveloperAppsViewController

- (void)parseAppsFromHTML:(NSString *)html {
    NSScanner *htmlScanner = [[NSScanner alloc] initWithString:html];
    
    //Jump to the table begining
    [htmlScanner scanUpToString:@"class=\"resultList\">" intoString:nil];

    NSString *appName = @"";
    NSString *appType = @"";
    NSString *appVersion = @"";
    NSString *appStatus = @"";
    NSString *appId = @"";
    NSString *appLastModified = @"";

    //first app begining
    [htmlScanner scanUpToString:@"<tr>" intoString:nil];

    while ([htmlScanner scanUpToString:@"<div class=\"software-column-type-col-0" intoString:nil]) {
        //App name
        if([htmlScanner scanUpToString:@"<a href=\"" intoString:nil]) {
            [htmlScanner scanUpToString:@"\">" intoString:nil];
            [htmlScanner scanString:@"\">" intoString:nil];
            [htmlScanner scanUpToString:@"</a" intoString:&appName];
            appName = [appName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            //App Type
            [htmlScanner scanUpToString:@"<div class=\"software-column-type-col-1" intoString:nil];
            [htmlScanner scanUpToString:@"<p>" intoString:nil];
            [htmlScanner scanString:@"<p>" intoString:nil];
            [htmlScanner scanUpToString:@"<" intoString:&appType];
            appType = [appType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            //App version
            [htmlScanner scanUpToString:@"<div class=\"software-column-type-col-2" intoString:nil];
            [htmlScanner scanUpToString:@"<p>" intoString:nil];
            [htmlScanner scanString:@"<p>" intoString:nil];
            [htmlScanner scanUpToString:@"<" intoString:&appVersion];
            appVersion = [appVersion stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            //App status
            [htmlScanner scanUpToString:@"<div class=\"software-column-type-col-3" intoString:nil];
            [htmlScanner scanUpToString:@"<p>" intoString:nil];
            [htmlScanner scanString:@"<p>" intoString:nil];
            [htmlScanner scanUpToString:@"<" intoString:&appStatus];
            appStatus = [appStatus stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            //App ID
            [htmlScanner scanUpToString:@"<div class=\"software-column-type-col-4" intoString:nil];
            [htmlScanner scanUpToString:@"<p>" intoString:nil];
            [htmlScanner scanString:@"<p>" intoString:nil];
            [htmlScanner scanUpToString:@"<" intoString:&appId];
            appId = [appId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            //App last modified
            [htmlScanner scanUpToString:@"<div class=\"software-column-type-col-5" intoString:nil];
            [htmlScanner scanUpToString:@"<p>" intoString:nil];
            [htmlScanner scanString:@"<p>" intoString:nil];
            [htmlScanner scanUpToString:@"<" intoString:&appLastModified];
            appLastModified = [appLastModified stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSLog(@"%@\t%@\t%@\t%@\t%@\t%@\t", appName, appId, appStatus, appType, appVersion, appLastModified);
            
            NSArray* nib = [[NSBundle mainBundle] loadNibNamed:@"BRDeveloperAppsViewController" owner:self options:nil];
            BRAppCell *cell = (BRAppCell *)[nib objectAtIndex:1];
            
            [[cell appName] setText:appName];
            [cell downloadIcon:appId];
            [_tableViewCells addObject:cell];

        }
    }
    
    [_tableview reloadData];
    [_activityIndicator stopAnimating];
    [_activityIndicator setHidden:YES];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self refreshApps:nil];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - IBActions

- (IBAction)login:(id)sender {
//    BRLoginFormViewController *loginForm_ = [[BRLoginFormViewController alloc] initWithNibName:@"BRLoginFormViewController" bundle:nil];
    BRLoginFormViewController *loginForm_ = [[BRLoginFormViewController alloc] init];
    __weak BRLoginFormViewController *loginForm = loginForm_;
    
    [loginForm setLoginFormTitle:@"iTunesConnect login"];
    [loginForm setLoginFormFooterNote:@"Use your iTunesConnect username and password to retrieve your app list"];
    [loginForm setCompletionBlock:^{
        _itcUsername = [BRLoginFormViewController username];
        _itcPassword = [BRLoginFormViewController password];
                
        if ([loginForm respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [loginForm dismissViewControllerAnimated:YES completion:NULL];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [loginForm dismissModalViewControllerAnimated:YES];
#pragma clang diagnostic pop
        }
        [self refreshApps:nil];
    }];
    
    if ([loginForm respondsToSelector:@selector(performSegueWithIdentifier:sender:)]) {
        //[self presentViewController:loginForm animated:YES completion:NULL];
        [self performSegueWithIdentifier:@"login" sender:self];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self performSegueWithIdentifier:@"login" sender:self];
        //[self presentModalViewController:loginForm animated:YES];
#pragma clang diagnostic pop
    }
}

- (IBAction)refreshApps:(id)sender {
    _itcUsername = [BRLoginFormViewController username];
    _itcPassword = [BRLoginFormViewController password];

    if (!(_itcPassword && _itcUsername)) {
        [self login:nil];
        return;
    }

    
    _tableViewCells = [[NSMutableArray alloc] init];
    
    [_activityIndicator setHidden:NO];
    [_activityIndicator startAnimating];
    
    ////////////////////
    
    NSURL *ittsBaseURL = [NSURL URLWithString:@"https://itunesconnect.apple.com"];
	NSString *ittsLoginPageAction = @"/WebObjects/iTunesConnect.woa";
	NSString *signoutSentinel = @"name=\"signOutForm\"";
    
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookieStorage cookiesForURL:ittsBaseURL];
	for (NSHTTPCookie *cookie in cookies) {
        NSLog(@"Cookie found: %@", cookie);
		[cookieStorage deleteCookie:cookie];
	}
    
    BRRestClient *restClient = [[BRRestClient alloc] init];
    [restClient setBaseURL:ittsBaseURL];
    [restClient read:ittsLoginPageAction withCompletionBlock:^{
        NSString *serverResponse = [restClient serverResponse];
        if ([serverResponse rangeOfString:signoutSentinel].location == NSNotFound) {
            // find the login action
            NSScanner *loginPageScanner = [NSScanner scannerWithString:serverResponse];
            [loginPageScanner scanUpToString:@"action=\"" intoString:nil];

            if (![loginPageScanner scanString:@"action=\"" intoString:nil]) {
                [[[UIAlertView alloc] initWithTitle:@"Error in login page"
                                            message:@"Can't find a correct login action in the login page"
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                return;
            }
            
            NSString *loginAction = nil;
            [loginPageScanner scanUpToString:@"\"" intoString:&loginAction];
            
            NSString *postString = [NSString stringWithFormat:@"theAccountName=%@&theAccountPW=%@&1.Continue.x=39&1.Continue.y=7",
                                    _itcUsername,
                                    _itcPassword];
            [restClient create:loginAction
                      withData:[postString dataUsingEncoding:NSUTF8StringEncoding]
            andCompletionBlock:^{
                NSString *serverResponse = [restClient serverResponse];

                NSString *signoutSentinel = @">Sign Out<";
                if (serverResponse == nil || [serverResponse rangeOfString:signoutSentinel].location == NSNotFound) {
                    [[[UIAlertView alloc] initWithTitle:@"Error while login"
                                                message:@"Can't connect to iTunesConnect."
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                    return;
                }
                
                /////////////////
                
                NSScanner *manageAppScanner = [NSScanner scannerWithString:serverResponse];
                [manageAppScanner scanUpToString:@"<b>Welcome, " intoString:nil];
                [manageAppScanner scanString:@"<b>Welcome, " intoString:nil];
                NSString *devName = @"";
                [manageAppScanner scanUpToString:@"</b>" intoString:&devName];
                _developerName = devName;
                
                [manageAppScanner scanUpToString:@"alt=\"Manage Your Apps\"" intoString:nil];
                if (![manageAppScanner scanString:@"alt=\"Manage Your Apps\"" intoString:nil]) {
                    [[[UIAlertView alloc] initWithTitle:@"Error in page"
                                                message:@"Can't find the \"Manage Your Apps\" link"
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                    return;
                }
                
                NSString *manageApplicationLink = nil;
                [manageAppScanner scanUpToString:@"href=\"" intoString:nil];
                [manageAppScanner scanString:@"href=\"" intoString:nil];
                [manageAppScanner scanUpToString:@"\"" intoString:&manageApplicationLink];
                
                NSLog(@"Manage your apps link: %@", manageApplicationLink);
                [restClient read:manageApplicationLink
             withCompletionBlock:^{
                 NSString *serverResponse = [restClient serverResponse];

                 
                 /////////////////
                 
                 NSScanner *seeAllScanner = [NSScanner scannerWithString:serverResponse];
                 [seeAllScanner scanUpToString:@"class=\"seeAll\"" intoString:nil];
                 if (![seeAllScanner scanString:@"class=\"seeAll\"" intoString:nil]) {
                     [[[UIAlertView alloc] initWithTitle:@"Error in page"
                                                 message:@"Can't find the \"See All\" link"
                                                delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil] show];
                     return;
                 }
                 
                 NSString *seeAllLink = nil;
                 [seeAllScanner scanUpToString:@"href=\"" intoString:nil];
                 [seeAllScanner scanString:@"href=\"" intoString:nil];
                 [seeAllScanner scanUpToString:@"\"" intoString:&seeAllLink];
                 
                 NSLog(@"See all link: %@", seeAllLink);
                 
                 [restClient read:seeAllLink withCompletionBlock:^{
                     [self parseAppsFromHTML:[restClient serverResponse]];
                 }];
             }];
            }];
        }
    }];
  
}

#pragma mark - UITableView delegate & data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 61.;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableViewCells count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Apps from %@", _developerName];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_tableViewCells objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (NSClassFromString(@"SLComposeViewController")) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            
            SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
                if (result == SLComposeViewControllerResultCancelled) {
                    NSLog(@"Cancelled");
                } else {
                    NSLog(@"Done");
                }
                
                [controller dismissViewControllerAnimated:YES completion:Nil];
            };
            controller.completionHandler = myBlock;
            

            NSString *postMessage = [NSString stringWithFormat:@"Review for %@ took XX days", [[[_tableViewCells objectAtIndex:indexPath.row] appName] text]];
            [controller setInitialText:[postMessage stringByAppendingString:@" | #iosreviewtime @Massale974"]];
            [controller addURL:[[_tableViewCells objectAtIndex:indexPath.row] appURL]];
            
            [self presentViewController:controller animated:YES completion:Nil];
            
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not available", nil)
                                        message:NSLocalizedString(@"No setup found for this service. Please verify you device settings.", nil)
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    } else if (NSClassFromString(@"TWTweetComposeViewController")) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        TWTweetComposeViewController *controller = [[TWTweetComposeViewController alloc] init];
#pragma clang diagnostic pop
        
        TWTweetComposeViewControllerCompletionHandler myBlock = ^(TWTweetComposeViewControllerResult result){
            if (result == TWTweetComposeViewControllerResultCancelled) {
                NSLog(@"Cancelled");
            } else {
                NSLog(@"Done");
            }
            
            [controller dismissViewControllerAnimated:YES completion:Nil];
        };
        controller.completionHandler =myBlock;
        
        NSString *postMessage = [NSString stringWithFormat:@"Review for %@ took XX days", [[[_tableViewCells objectAtIndex:indexPath.row] appName] text]];
        [controller setInitialText:[postMessage stringByAppendingString:@" | #iosreviewtime @Massale974"]];
        [controller addURL:[[_tableViewCells objectAtIndex:indexPath.row] appURL]];
        
        [self presentViewController:controller animated:YES completion:Nil];
    }
    
}

@end
