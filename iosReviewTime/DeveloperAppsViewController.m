//
//  DeveloperAppsViewController.m
//  iOSReviewTime
//
//  Created by iRare Media on 12/20/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "DeveloperAppsViewController.h"

@implementation DeveloperAppsViewController
@synthesize developerName, tableViewCells, dictionaryData, appURLs;
@synthesize loginView, activityIndicator, tableview;
@synthesize loginButton, refreshButton;

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    developerName = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    
    if (developerName != NULL) {
        loginButton.title = NSLocalizedString(@"Logout", @"Button Title");
        [self refreshApps];
    } else {
        loginButton.title = NSLocalizedString(@"Login", @"Button Title");
        [self performSelector:@selector(login) withObject:nil afterDelay:1.0];
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - Login

- (IBAction)login {
    [self performSegueWithIdentifier:@"login" sender:self];
}

- (void)didLoginUser {
    if (developerName != NULL) {
        loginButton.title = NSLocalizedString(@"Logout", @"Button Title");
    } else {
        loginButton.title = NSLocalizedString(@"Login", @"Button Title");
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
    
    developerName = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    NSString *formattedName = [developerName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestURL = [NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&media=software&lang=en_US&country=US", formattedName];
    if (developerName == nil) {
        [self login];
        return;
    }
    
    tableViewCells = [[NSMutableArray alloc] init];
    appURLs = [[NSMutableArray alloc] init];
    
    [activityIndicator setHidden:NO];
    [activityIndicator startAnimating];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:requestURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            // NSString *appScreenshot = [[result objectForKey:@"screenshotUrls"] firstObject];
            [appURLs addObject:appURL];
            
            static NSString *CellIdentifier = @"ID";
            UITableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            
            [cell.imageView setImageWithURL:[NSURL URLWithString:appIcon]]; // placeholderImage:[UIImage imageNamed:@"appglobe"]];
            // [cell.imageView setFrame:CGRectMake(cell.imageView.frame.origin.x, cell.imageView.frame.origin.x, 50, 50)];
            // [cell.imageView.layer setCornerRadius:4];
            // [cell.imageView.layer setRasterizationScale:[UIScreen mainScreen].scale];
            // [cell.imageView.layer setShouldRasterize:YES];
            cell.textLabel.text = appName;
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ | %@", nil), appVersion, appGenre];
            [tableViewCells addObject:cell];
        }
        
        [tableview reloadData];
        [activityIndicator stopAnimating];
        [activityIndicator setHidden:YES];
        refreshButton.enabled = YES;
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
    developerName = [FDKeychain itemForKey:@"developerName" forService:@"iOSReviewTime" error:nil];
    if (developerName == NULL) return 0;
    else return [tableViewCells count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (developerName != NULL) return [NSString stringWithFormat:NSLocalizedString(@"Apps created by %@", nil), developerName];
    else return NSLocalizedString(@"To tweet about your app review times, tap the login button and type your Organization / Team name", nil);
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

@end
