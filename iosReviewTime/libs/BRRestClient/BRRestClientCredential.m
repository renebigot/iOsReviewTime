//
//  BRRestClientCredential.m
//  AppCharts
//
//  Created by René Bigot on 10/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRRestClientCredential.h"

@implementation BRRestClientCredential

+ (id)logonDataWithUser:(NSString *)user andPassword:(NSString *)password {
    BRRestClientCredential *retVal = [[BRRestClientCredential alloc] init];
    [retVal setUser:user];
    [retVal setPassword:password];
    return retVal;
}

- (NSURLCredential *)credential {
    return [NSURLCredential credentialWithUser:[self.user lowercaseString]
                                      password:self.password
                                   persistence:NSURLCredentialPersistenceNone];
}

@end
