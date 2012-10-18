//
//  BRRestClientCredential.h
//  AppCharts
//
//  Created by René Bigot on 10/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRRestClientCredential : NSObject

+ (id)logonDataWithUser:(NSString *)user andPassword:(NSString *)password;
- (NSURLCredential *)credential;

@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *password;

@end
