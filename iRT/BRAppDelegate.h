//
//  BRAppDelegate.h
//  iRT
//
//  Created by René Bigot on 21/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BRAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusMenuItem;
    NSDecimalNumber *_tweetsCount;
    
    NSTimer *tweetsTimer;
}

@end
