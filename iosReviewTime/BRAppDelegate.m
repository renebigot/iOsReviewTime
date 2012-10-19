//
//  BRAppDelegate.m
//  iosReviewTime
//
//  Created by René Bigot on 14/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRAppDelegate.h"

#import "BRReviewTimeViewController.h"
#import "BRDeveloperAppsViewController.h"

@implementation BRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    BRReviewTimeViewController *reviewTimeViewController = [[BRReviewTimeViewController alloc] initWithNibName:@"BRReviewTimeViewController"
                                                                                                        bundle:nil];
    [reviewTimeViewController setTitle:@"Review time"];
    [reviewTimeViewController.tabBarItem setImage:[UIImage imageNamed:@"clock"]];
    
    BRDeveloperAppsViewController *appsViewController = [[BRDeveloperAppsViewController alloc] initWithNibName:@"BRDeveloperAppsViewController"
                                                                                                        bundle:nil];
    [appsViewController setTitle:@"App list"];
    [appsViewController.tabBarItem setImage:[UIImage imageNamed:@"appglobe.png"]];

    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:reviewTimeViewController, appsViewController, nil]];
    self.window.rootViewController = tabBarController;
    
    [application setStatusBarStyle:UIStatusBarStyleDefault];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
