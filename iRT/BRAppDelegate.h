//
//  BRAppDelegate.h
//  iRT
//
//  Created by René Bigot on 21/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface BRAppDelegate : NSObject <NSApplicationDelegate, NSURLConnectionDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusMenuItem;
    
    NSTimer *tweetsTimer;
}

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *requestData;
@property (strong, nonatomic) NSURL *apiURL;
@property (strong, nonatomic) NSMutableArray *results;

@property (strong, nonatomic) NSDecimalNumber *tweetsCount;

@end
