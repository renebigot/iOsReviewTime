//
//  PurchaseFetchViewController.h
//  iOS Review Time
//
//  Created by iRare Media on 12/27/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "EBPurchase.h"
#import "FDKeychain.h"

#define PRODUCT_ID @"com.ReviewTime.BackgroundFetch"

@interface PurchaseFetchViewController : UIViewController <EBPurchaseDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;

- (IBAction)done:(id)sender;
- (IBAction)purchase:(id)sender;
- (IBAction)restorePurchase:(id)sender;

@end
