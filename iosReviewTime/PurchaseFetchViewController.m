//
//  PurchaseFetchViewController.m
//  iOS Review Time
//
//  Created by iRare Media on 12/27/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "PurchaseFetchViewController.h"

@interface PurchaseFetchViewController ()

@end

@implementation PurchaseFetchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)purchase:(id)sender {
    // TODO: Add iAP Non-Consumable purchase feature
}

- (IBAction)restorePurchase:(id)sender {
    // TODO: Add iAP Non-Consumable restore purchase feature
}

@end
