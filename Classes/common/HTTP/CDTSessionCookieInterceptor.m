//
//  CDTSessionCookieInterceptor.m
//
//
//  Created by Rhys Short on 08/09/2015.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import "CDTSessionCookieInterceptor.h"
#import "CDTLogging.h"

@interface CDTSessionCookieInterceptor ()

@property (nonnull, strong, nonatomic) NSString *cookieRequestBody;
@property (nonatomic) BOOL shouldMakeCookieRequest;
@property (nullable, strong, nonatomic) NSString *cookie;
@property (nonnull, nonatomic, strong) NSURLSession *urlSession;

@end

@implementation CDTSessionCookieInterceptor

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (self) {
        _cookieRequestBody = [NSString stringWithFormat:@"name=%@&password=%@", username, password];
        _shouldMakeCookieRequest = YES;
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (CDTHTTPInterceptorContext *)interceptRequestInContext:(CDTHTTPInterceptorContext *)context
{
    if (self.shouldMakeCookieRequest) {
        if (!self.cookie) {
            // get the cookie
            self.cookie = [self newCookieForRemote:context.request.URL];
        }
        [context.request setValue:self.cookie forHTTPHeaderField:@"Cookie"];
    }

    return context;
}

- (CDTHTTPInterceptorContext *)interceptResponseInContext:(CDTHTTPInterceptorContext *)context
{
    // check the response code.
    if (context.response.statusCode == 401) {
        // reset the cookie, let the request interceptor handle getting a new cookie.
        self.cookie = nil;
        context.shouldRetry = YES;
    }

    return context;
}

- (nullable NSString *)newCookieForRemote:(NSURL *)url
{
    NSString *scheme = [url scheme];
    NSNumber *port = [url port];
    if (!port) {
        if ([scheme isEqualToString:@"https"]) {
            port = @(443);
        } else {
            port = @(80);
        }
    }

    NSURL *sessionUrl = [NSURL
        URLWithString:[NSString stringWithFormat:@"%@://%@:%@/_session", scheme, [url host], port]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:sessionUrl];
    request.HTTPBody = [self.cookieRequestBody dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    __block NSString *cookie = nil;
    NSURLSessionDataTask *task = [self.urlSession
        dataTaskWithRequest:request
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // all parameters to block are nullable, annotations removed
            // to provide compatbility with xcode 6.4 and xcode 7
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            // handle response being nil
            if ([httpResp statusCode] / 100 == 2) {
                // we have the cookie. maybe
                if (data && [self hasSessionStarted:data]) {
                    // get the cookie from the header
                    NSString *cookieHeader = [[httpResp allHeaderFields] valueForKey:@"Set-Cookie"];

                    cookie = [cookieHeader componentsSeparatedByString:@";"][0];

                } else {
                    cookie = nil;
                }
            } else if ([httpResp statusCode] == 401) {
                CDTLogError(CDTREPLICATION_LOG_CONTEXT, @"Credentials are incorrect, cookie "
                                                        @"authentication will not be attempted "
                                                        @"again by this interceptor object");
                self.shouldMakeCookieRequest = NO;
            } else if ([httpResp statusCode] / 100 == 5) {
                CDTLogError(CDTREPLICATION_LOG_CONTEXT,
                            @"Failed to get cookie from the server, response code was %ld cookie "
                            @"authentication will not be attempted again by this interceptor "
                            @"object",
                            (long)[httpResp statusCode]);
                self.shouldMakeCookieRequest = NO;
            } else {
                CDTLogError(CDTREPLICATION_LOG_CONTEXT,
                            @"Failed to get cookie from the server,response code %ld cookie "
                            @"authentication will not be attempted again by this interceptor "
                            @"object",
                            (long)[httpResp statusCode]);
            }

          }];
    [task resume];

    while (task.state != NSURLSessionTaskStateCompleted) {
        [NSThread sleepForTimeInterval:0.1f];
    }

    return cookie;
}

- (BOOL)hasSessionStarted:(nonnull NSData *)data
{
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    // only check for ok:true, https://issues.apache.org/jira/browse/COUCHDB-1356
    // means we cannot check that the name returned is the one we sent.
    return
        [jsonResponse objectForKey:@"ok"] != nil && [[jsonResponse objectForKey:@"ok"] boolValue];
}

- (void)dealloc { [self.urlSession invalidateAndCancel]; }
@end
