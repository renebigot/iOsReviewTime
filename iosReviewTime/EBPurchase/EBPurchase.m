//
//  EBPurchase.m
//  Simple In-App Purchase for iOS
//
//  Created by Dave Wooldridge, Electric Butterfly, Inc.
//  Copyright (c) 2011 Electric Butterfly, Inc. - http://www.ebutterfly.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy 
//  of this software and associated documentation files (the "Software"), to 
//  redistribute it and use it in source and binary forms, with or without 
//  modification, subject to the following conditions:
// 
//  1. This Software may be used for any purpose, including commercial applications.
// 
//  2. This Software in source code form may be redistributed freely and must 
//  retain the above copyright notice, this list of conditions and the following 
//  disclaimer. Altered source versions must be plainly marked as such, and must 
//  not be misrepresented as being the original Software.
// 
//  3. Neither the name of the author nor the name of the author's company may be 
//  used to endorse or promote products derived from this Software without specific 
//  prior written permission.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "EBPurchase.h"

@implementation EBPurchase

@synthesize delegate;
@synthesize validProduct;


- (BOOL)requestProduct:(NSString *)productId  {
    if (productId != nil) {

        NSLog(@"EBPurchase requestProduct: %@", productId);
        
        if ([SKPaymentQueue canMakePayments]) {
            // Yes, In-App Purchase is enabled on this device.
            // Proceed to fetch available In-App Purchase items.
            
            // Initiate a product request of the Product ID.
            SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
            prodRequest.delegate = self;
            [prodRequest start];
            
            return YES;
            
        } else {
            // Notify user that In-App Purchase is Disabled.
            
            NSLog(@"EBPurchase requestProduct: IAP Disabled");
            
            return NO;
        }
        
    } else {
        
        NSLog(@"EBPurchase requestProduct: productId = NIL");
        
        return NO;
    }
    
    	
}

-(BOOL)purchaseProduct:(SKProduct*)requestedProduct {
    if (requestedProduct != nil) {
        
        NSLog(@"EBPurchase purchaseProduct: %@", requestedProduct.productIdentifier);
        
        if ([SKPaymentQueue canMakePayments]) {
            // Yes, In-App Purchase is enabled on this device.
            // Proceed to purchase In-App Purchase item.
            
            // Assign a Product ID to a new payment request.
            SKPayment *paymentRequest = [SKPayment paymentWithProduct:requestedProduct]; 
            
            // Assign an observer to monitor the transaction status.
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
            
            // Request a purchase of the product.
            [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
            
            return YES;
            
        } else {
            // Notify user that In-App Purchase is Disabled. 
            
            NSLog(@"EBPurchase purchaseProduct: IAP Disabled");
            
            return NO;
        }
        
    } else {
        
        NSLog(@"EBPurchase purchaseProduct: SKProduct = NIL");
        
        return NO;
    }
}

- (BOOL)restorePurchase {
    NSLog(@"EBPurchase restorePurchase");
    
    if ([SKPaymentQueue canMakePayments]) {
        // Yes, In-App Purchase is enabled on this device.
        // Proceed to restore purchases.
                
        // Assign an observer to monitor the transaction status.
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        // Request to restore previous purchases.
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        
        return YES;
        
    } else {
        // Notify user that In-App Purchase is Disabled.        
        return NO;
    }
}

#pragma mark -
#pragma mark SKProductsRequestDelegate Methods

// Store Kit returns a response from an SKProductsRequest.
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
	// Parse the received product info.
	self.validProduct = nil;
	int count = (int)[response.products count];
	if (count>0) {
        // Grab the first product in the array.
		self.validProduct = [response.products objectAtIndex:0];
	}
	if (self.validProduct) {
        // Yes, product is available, so return values.
        
        if ([delegate respondsToSelector:@selector(requestedProduct:identifier:name:price:description:)])
            [delegate requestedProduct:self identifier:self.validProduct.productIdentifier name:self.validProduct.localizedTitle price:[self.validProduct.price stringValue] description:self.validProduct.localizedDescription];
        
	} else {
        // No, product is NOT available, so return nil values.
        
        if ([delegate respondsToSelector:@selector(requestedProduct:identifier:name:price:description:)])
            [delegate requestedProduct:self identifier:nil name:nil price:nil description:nil];
  }
}


#pragma mark - SKPaymentTransactionObserver Methods

// The transaction status of the SKPaymentQueue is sent here.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for(SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
				
			case SKPaymentTransactionStatePurchasing:
				// Item is still in the process of being purchased
				break;
				
			case SKPaymentTransactionStatePurchased:
				// Item was successfully purchased!
				
				// Return transaction data. App should provide user with purchased product.
                if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:receipt:)])
                    [delegate successfulPurchase:self restored:NO identifier:transaction.payment.productIdentifier receipt:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
				
				// After customer has successfully received purchased content,
				// remove the finished transaction from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
				
			case SKPaymentTransactionStateRestored:
				// Verified that user has already paid for this item.
				// Ideal for restoring item across all devices of this customer.
				
				// Return transaction data. App should provide user with purchased product.
                if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:receipt:)])
                    [delegate successfulPurchase:self restored:YES identifier:transaction.payment.productIdentifier receipt:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
                
				// After customer has restored purchased content on this device,
				// remove the finished transaction from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
				
			case SKPaymentTransactionStateFailed:
				// Purchase was either cancelled by user or an error occurred.
				
				if (transaction.error.code != SKErrorPaymentCancelled) {
                    
                    // A transaction error occurred, so notify user.
                    if ([delegate respondsToSelector:@selector(failedPurchase:error:message:)])
                        [delegate failedPurchase:self error:transaction.error.code message:transaction.error.localizedDescription];
				}
                
				// Finished transactions should be removed from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
		}
	}
}

// Called when one or more transactions have been removed from the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    NSLog(@"EBPurchase removedTransactions");
    
    // Release the transaction observer since transaction is finished/removed.
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

// Called when SKPaymentQueue has finished sending restored transactions.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    
    NSLog(@"EBPurchase paymentQueueRestoreCompletedTransactionsFinished");
    
    if ([queue.transactions count] == 0) {
        // Queue does not include any transactions, so either user has not yet made a purchase
        // or the user's prior purchase is unavailable, so notify app (and user) accordingly.
        
        NSLog(@"EBPurchase restore queue.transactions count == 0");
        
        // Release the transaction observer since no prior transactions were found.
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
        
        if ([delegate respondsToSelector:@selector(incompleteRestore:)])
            [delegate incompleteRestore:self];
        
    } else {
        // Queue does contain one or more transactions, so return transaction data.
        // App should provide user with purchased product.
        
        NSLog(@"EBPurchase restore queue.transactions available");
        
        for(SKPaymentTransaction *transaction in queue.transactions) {

            NSLog(@"EBPurchase restore queue.transactions - transaction data found");
            
            if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:receipt:)])
                [delegate successfulPurchase:self restored:YES identifier:transaction.payment.productIdentifier receipt:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
        }
    }
}

// Called if an error occurred while restoring transactions.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    // Restore was cancelled or an error occurred, so notify user.

    NSLog(@"EBPurchase restoreCompletedTransactionsFailedWithError");

    if ([delegate respondsToSelector:@selector(failedRestore:error:message:)])
        [delegate failedRestore:self error:error.code message:error.localizedDescription];
}


@end
