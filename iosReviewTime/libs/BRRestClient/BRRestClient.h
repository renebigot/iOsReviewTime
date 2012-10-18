//
//  BRRestClient.h
//  AppCharts
//
//  Created by René Bigot on 10/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRRestClientCredential.h"


@interface BRRestClient : NSObject <NSURLConnectionDataDelegate> {
    NSInteger _status;
    
    NSURL *_url;
    NSMutableData *_receivedData;
    NSError *_error;

    void (^_readCompletionBlock)(void);
}

- (void)setUser:(NSString *)user withPassword:(NSString *)password;
- (void)read:(NSString *)URI withCompletionBlock:(void (^)(void))completionBlock;
- (void)read:(NSString *)URI withCompletionBlock:(void (^)(void))completionBlock error:(NSError **)error;
- (void)create:(NSString *)URI withData:(NSData *)data completionBlock:(void (^)(void))completionBlock error:(NSError **)error;
- (void)create:(NSString *)URI withData:(NSData *)data andCompletionBlock:(void (^)(void))completionBlock;
- (NSString *)statusCode;
- (NSData *)rawServerResponse;
- (NSString *)serverResponse;
- (NSString *)serverResponseWithEncoding:(NSStringEncoding)encoding;

@property (nonatomic) BOOL hideError;
@property (nonatomic, strong) BRRestClientCredential *authentification;
@property (nonatomic, strong) NSURL *baseURL;

@end
