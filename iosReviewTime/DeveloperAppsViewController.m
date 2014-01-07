//
//  DeveloperAppsViewController.m
//  iOSReviewTime
//
//  Created by iRare Media on 12/20/13.
//  Copyright (c) 2012 René Bigot. Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "DeveloperAppsViewController.h"

@interface DeveloperAppsViewController () {
    BOOL didPresentLogin;
} @end

@implementation DeveloperAppsViewController
@synthesize developerNameOrId, tableViewCells, dictionaryData, appURLs;
@synthesize loginView, activityIndicator, tableview;
@synthesize loginButton, refreshButton;

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    didPresentLogin = NO;
    developerNameOrId = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    if (developerNameOrId != NULL) {
        loginButton.title = NSLocalizedString(@"Search", @"Button Title");
        [self refreshApps];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    developerNameOrId = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    
    if (didPresentLogin) {
        if (developerNameOrId != NULL) {
            loginButton.title = NSLocalizedString(@"Search", @"Button Title");
            if ([developerNameOrId integerValue] > 0)
                [self refreshApps];
        }
    } else {
        if (developerNameOrId == NULL) {
            loginButton.title = NSLocalizedString(@"Search", @"Button Title");
            [self performSelector:@selector(login) withObject:nil afterDelay:1.0];
        }
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - Login

- (IBAction)login {
    didPresentLogin = YES;
    [self performSegueWithIdentifier:@"login" sender:self];
}

- (void)didLoginUser {
    if (developerNameOrId != NULL) {
        loginButton.title = NSLocalizedString(@"Search", @"Button Title");
    } else {
        loginButton.title = NSLocalizedString(@"Search", @"Button Title");
    }
    
    [self refreshApps];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"login"]) {
        loginView = segue.destinationViewController;
        loginView.delegate = self;
    }
}

#pragma mark - Data Parsing

- (IBAction)refreshApps {
    refreshButton.enabled = NO;
    
    developerNameOrId = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    
    NSString *requestURL = nil;
    //Searching developer ID ?
    if ([developerNameOrId integerValue] > 0) {
        _developerScreenName = nil;
        requestURL = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@&entity=software", developerNameOrId];
    } else {
        _developerScreenName = developerNameOrId;
        NSString *formattedName = [developerNameOrId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        requestURL = [NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&media=software&lang=en_US&country=US", formattedName];
    }
    
    if (developerNameOrId == nil) {
        [self login];
        return;
    }
    
    tableViewCells = [[NSMutableArray alloc] init];
    appURLs = [[NSMutableArray alloc] init];
    
    [activityIndicator setHidden:NO];
    [activityIndicator startAnimating];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        _developersArray = [[NSMutableArray alloc] init];
        
        dictionaryData = responseObject;

        // Loop through the "results" array inside the returned dictionary - get each dictionary result inside of the results array
        for (NSDictionary *result in [dictionaryData objectForKey:@"results"]) {
            // Check if the listing matches the correct listing kind (ex. apps, not songs or movies). Use the "kind" tag and check for "software" value
            if (![[result objectForKey:@"kind"] isEqualToString:@"software"]) continue;
            
            /* Collect the following data about each app
             • Name (trackName)
             • Genre (primaryGenreName)
             • Version (version)
             • Last Updated (releaseDate)
             • User Rating (averageUserRating)
             • ID (bundleId)
             • Icon (artworkUrl512)
             • URL (trackViewUrl)
             • Screenshot (first object in screenshotUrls array)
             */
            
            NSString *appName = [result objectForKey:@"trackName"];
            NSString *appGenre = [result objectForKey:@"primaryGenreName"];
            NSString *appVersion = [result objectForKey:@"version"];
            // NSString *appLastUpdated = [result objectForKey:@"releaseDate"];
            // NSString *appRating = [result objectForKey:@"averageUserRating"];
            // NSString *appID = [result objectForKey:@"bundleId"];
            NSString *appIcon = [result objectForKey:@"artworkUrl100"]; // Can also request a 60x60 px version or a 512x512 px version
            NSString *appURL = [result objectForKey:@"trackViewUrl"];
            
            NSDictionary *tmpArtistDict = @{@"name": result[@"artistName"], @"id": [result[@"artistId"] stringValue]};
            if (!_developerScreenName) {
                _developerScreenName = result[@"artistName"];
            } else if (![_developersArray containsObject:tmpArtistDict]) {
                [_developersArray addObject:tmpArtistDict];
            }
            
            // NSString *appScreenshot = [[result objectForKey:@"screenshotUrls"] firstObject];
            [appURLs addObject:appURL];
            
            static NSString *CellIdentifier = @"ID";
            UITableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
            // [cell.imageView setImageWithURL:[NSURL URLWithString:appIcon]]; // placeholderImage:[UIImage imageNamed:@"appglobe"]];
            cell.imageView.image = [UIImage imageNamed:@"iosGrid"];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(queue, ^(void) {
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:appIcon]];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.imageView.image = image;
                        [cell setNeedsLayout];
                    });
                }
            });
            
            
            // [cell.imageView setFrame:CGRectMake(cell.imageView.frame.origin.x, cell.imageView.frame.origin.x, 50, 50)];
            // [cell.imageView.layer setCornerRadius:4];
            // [cell.imageView.layer setRasterizationScale:[UIScreen mainScreen].scale];
            // [cell.imageView.layer setShouldRasterize:YES];
            cell.textLabel.text = appName;
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ | %@", nil), appVersion, appGenre];
            [tableViewCells addObject:cell];
        }
        
        [tableview reloadData];
        [tableview setScrollIndicatorInsets:UIEdgeInsetsMake(0., 0., 50., 0.)];
        [tableview setContentInset:UIEdgeInsetsMake(0., 0., 50., 0.)];
        
        [activityIndicator stopAnimating];
        [activityIndicator setHidden:YES];
        refreshButton.enabled = YES;
        
        if ([_developersArray count] > 1) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Many results found for \"%@\" found. Which one do you want to use ?", nil), developerNameOrId]
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];
            for (NSDictionary *developerDict in _developersArray) {
                [actionSheet addButtonWithTitle:developerDict[@"name"]];
            }
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [actionSheet setCancelButtonIndex:[actionSheet numberOfButtons] - 1];

            didPresentLogin = YES;
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [activityIndicator stopAnimating];
        [activityIndicator setHidden:YES];
        refreshButton.enabled = YES;
    }];
}

#pragma mark - UITableView Delegate & DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 61;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    developerNameOrId = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    if (developerNameOrId == NULL) return 0;
    else return [tableViewCells count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (developerNameOrId != NULL) {
        return [NSString stringWithFormat:NSLocalizedString(@"Apps created by %@", nil), _developerScreenName];
    } else {
        return NSLocalizedString(@"To tweet about your app review times, tap the login button and type your Organization / Team name", nil);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableViewCells objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
        [controller dismissViewControllerAnimated:YES completion:Nil];
    };
    controller.completionHandler = myBlock;
    
    NSString *postMessage = [NSString stringWithFormat:NSLocalizedString(@"Review for %@ took XX days", nil), [[tableViewCells objectAtIndex:indexPath.row] textLabel].text];
    [controller setInitialText:[postMessage stringByAppendingString:@" #iosreviewtime"]];
    [controller addURL:[NSURL URLWithString:[appURLs objectAtIndex:indexPath.row]]];
    [controller addImage:[[tableViewCells objectAtIndex:indexPath.row] imageView].image];
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex > [_developersArray count])
        return;

    [FDKeychain saveItem:_developersArray[buttonIndex][@"id"]
                  forKey:@"developerName"
              forService:@"iOSReviewTime"
                   error:nil];
    
    [self refreshApps];
}

@end
