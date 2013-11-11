//
//  BRRestClient.m
//  AppCharts
//
//  Created by René Bigot on 10/10/12.
//  Copyright (c) 2012 René Bigot. All rights reserved.
//

#import "BRRestClient.h"

@implementation BRRestClient

#pragma mark - Instances Methods

- (void)setUser:(NSString *)user withPassword:(NSString *)password {
    self.authentification = [BRRestClientCredential logonDataWithUser:user andPassword:password];
}

- (void)create:(NSString *)URI withData:(NSData *)data andCompletionBlock:(void (^)(void))completionBlock {
    [self create:URI withData:data completionBlock:completionBlock error:NULL];
}

- (void)create:(NSString *)URI withData:(NSData *)data completionBlock:(void (^)(void))completionBlock error:(NSError **)error {
    if (error != NULL)
        _error = *error;
    
    _status = 0;
    NSString *referer = nil;
    
    if (_url) {
        referer = [NSString stringWithFormat:@"%@", _url];
    }
    
    _url = [[NSURL alloc] initWithScheme:[self.baseURL scheme]
                                          host:[self.baseURL host]
                                          path:[[self.baseURL path] stringByAppendingString:URI]];
    NSLog(@"Request URL : %@", _url);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    if (connection) {
        _readCompletionBlock = completionBlock;
    } else {
        _readCompletionBlock = NULL;
        
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   NSLocalizedString(@"Connection error", nil), NSLocalizedDescriptionKey,
								   NSLocalizedString(@"Can't connect with this connection definition", nil), NSLocalizedFailureReasonErrorKey,
								   nil];
        _error = [NSError errorWithDomain:@"BRRestClient HTTP Error" code:_status userInfo:errorDict];

        if (!self.hideError) {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
            [[[UIAlertView alloc] initWithTitle:[_error localizedDescription]
                                        message:[[_error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
#endif
        }
    }
}

- (void)read:(NSString *)URI withCompletionBlock:(void (^)(void))completionBlock {
    [self read:URI withCompletionBlock:completionBlock error:NULL];
}

- (void)read:(NSString *)URI withCompletionBlock:(void (^)(void))completionBlock error:(NSError **)error {
    if (error != NULL)
        _error = *error;
    
    _status = 0;    
    NSString *referer = nil;
    
    if (_url) {
        referer = [NSString stringWithFormat:@"%@", _url];
    }
    _url = [[NSURL alloc] initWithScheme:[self.baseURL scheme]
                                           host:[self.baseURL host]
                                           path:[[self.baseURL path] stringByAppendingString:URI]];
    NSLog(@"Request URL : %@", _url);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];

    if (referer) {
        [request setValue:referer forHTTPHeaderField:@"Referer"];
    }
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];

    if (connection) {
        _readCompletionBlock = completionBlock;
    } else {
        _readCompletionBlock = NULL;
        
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   NSLocalizedString(@"Connection error", nil), NSLocalizedDescriptionKey,
								   NSLocalizedString(@"Can't connect with this connection definition", nil), NSLocalizedFailureReasonErrorKey,
								   nil];
        _error = [NSError errorWithDomain:@"BRRestClient HTTP Error" code:_status userInfo:errorDict];
        
        if (!self.hideError) {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
            [[[UIAlertView alloc] initWithTitle:[_error localizedDescription]
                                        message:[[_error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
#endif
        }
    }
}

- (NSString *)statusCode {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    return [NSString stringWithFormat:@"%ld", (long)_status];
#else
    return [NSString stringWithFormat:@"%ld", _status];
#endif
}

- (NSData *)rawServerResponse {
    return _receivedData;
}

- (NSString *)serverResponse {
    return [self serverResponseWithEncoding:NSUTF8StringEncoding];
}

- (NSString *)serverResponseWithEncoding:(NSStringEncoding)encoding {
    return [[NSString alloc] initWithData:_receivedData encoding:encoding];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        // Return credentials
		NSURLCredential *credential = [self.authentification credential];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        
	} else {
        // Cancel challenge if it failed previously
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        _status = [(NSHTTPURLResponse *)response statusCode];
        if (_status / 100 != 2 && _status / 100 != 3) {
            connection = nil;
            _receivedData = nil;

            NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [self statusDescriptionForCode:_status], NSLocalizedDescriptionKey,
                                       [self statusDescriptionForCode:_status], NSLocalizedFailureReasonErrorKey,
                                       nil];
            _error = [NSError errorWithDomain:@"BRRestClient HTTP Error" code:_status userInfo:errorDict];

            if (!self.hideError) {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                [[[UIAlertView alloc] initWithTitle:@"Server Error"
                                            message:[NSString stringWithFormat:@"%@\n%@", [_error localizedDescription], [[_error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]]
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
#endif
            }
        }
    }

    _receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    connection = nil;
    _receivedData = nil;
    
    _error = error;
    if (!self.hideError) {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        [[[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                    message:[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
#endif
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[_receivedData length]);
#else
    NSLog(@"Succeeded! Received %ld bytes of data",[_receivedData length]);
#endif
    
    connection = nil;
    _readCompletionBlock();
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response) {
        NSMutableURLRequest *r = [request mutableCopy];
        [r setURL: [request URL]];
        return r;
    } else {
        return request;
    }
}

- (NSString *)statusDescriptionForCode:(NSInteger)statusCode {
    NSDictionary *_restClientHttpError = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"Continue", @"100",
                                          @"Switching Protocols", @"101",
                                          @"OK", @"200",
                                          @"Created", @"201",
                                          @"Accepted", @"202",
                                          @"Non-Authoritative Information", @"203",
                                          @"No Content", @"204",
                                          @"Reset Content", @"205",
                                          @"Partial Content", @"206",
                                          @"Multiple Choices", @"300",
                                          @"Moved Permanently", @"301",
                                          @"Found", @"302",
                                          @"See Other", @"303",
                                          @"Not Modified", @"304",
                                          @"Use Proxy", @"305",
                                          @"(Unused)", @"306",
                                          @"Temporary Redirect", @"307",
                                          @"Bad Request", @"400",
                                          @"Unauthorized", @"401",
                                          @"Payment Required", @"402",
                                          @"Forbidden", @"403",
                                          @"Not Found", @"404",
                                          @"Method Not Allowed", @"405",
                                          @"Not Acceptable", @"406",
                                          @"Proxy Authentication Required", @"407",
                                          @"Request Timeout", @"408",
                                          @"Conflict", @"409",
                                          @"Gone", @"410",
                                          @"Length Required", @"411",
                                          @"Precondition Failed", @"412",
                                          @"Request Entity Too Large", @"413",
                                          @"Request-URI Too Long", @"414",
                                          @"Unsupported Media Type", @"415",
                                          @"Requested Range Not Satisfiable", @"416",
                                          @"Expectation Failed", @"417",
                                          @"Internal Server Error", @"500",
                                          @"Not Implemented", @"501",
                                          @"Bad Gateway", @"502",
                                          @"Service Unavailable", @"503",
                                          @"Gateway Timeout", @"504",
                                          @"HTTP Version Not Supported", @"505",
                                          nil];
    return [_restClientHttpError objectForKey:[NSString stringWithFormat:@"%ld", (long)statusCode]];
}
@end
