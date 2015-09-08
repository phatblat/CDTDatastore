//
//  CDTCookieInterceptorTests.m
//  Tests
//
//  Created by Rhys Short on 09/09/2015.
//
//

#import <XCTest/XCTest.h>
#import "CloudantSyncTests.h"
#import "CDTCookieInterceptor.h"

// expose properties so we can look at them
@interface CDTCookieInterceptor ()

@property (nonatomic) BOOL shouldMakeCookieRequest;
@property (nullable, strong, nonatomic) NSString *cookie;
@property (nonnull, nonatomic, strong) NSURLSession *urlSession;

@end

@interface CookieResponseURLProtocol : NSURLProtocol

@end

@implementation CookieResponseURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request { return YES; }
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request { return request; }
- (void)startLoading
{
    NSURLRequest *request = [self request];
    id client = [self client];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
         initWithURL:[request URL]
          statusCode:200
         HTTPVersion:@"HTTP/1.1"
        headerFields:@{
            @"Set-Cookie" : @"AuthSession=cm9vdDo1MEJCRkYwMjq0LO0ylOIwShrgt8y-UkhI-c6BGw; "
                            @"Version=1; Path=/; HttpOnly"
        }];
    [client URLProtocol:self
        didReceiveResponse:response
        cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    NSDictionary *responseDict =
        @{ @"ok" : @(YES),
           @"name" : @"username",
           @"roles" : @[ @"_admin" ] };
    NSData *respData = [NSJSONSerialization dataWithJSONObject:responseDict options:0 error:nil];

    [client URLProtocol:self didLoadData:respData];
    [client URLProtocolDidFinishLoading:self];
}

@end

@interface Always401UrlProtocol : NSURLProtocol

@end

@implementation Always401UrlProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request { return YES; }
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request { return request; }
- (void)startLoading
{
    NSURLRequest *request = [self request];
    id client = [self client];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                              statusCode:401
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{}];
    [client URLProtocol:self
        didReceiveResponse:response
        cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [client URLProtocol:self didLoadData:[NSData data]];
    [client URLProtocolDidFinishLoading:self];
}

@end

@interface CDTCookieInterceptorTests : CloudantSyncTests

@end

@implementation CDTCookieInterceptorTests

- (void)testCookieInterceptorSuccessfullyGetsCookie
{
    NSString *expectedCookieString = @"AuthSession=cm9vdDo1MEJCRkYwMjq0LO0ylOIwShrgt8y-UkhI-c6BGw";
    CDTCookieInterceptor *interceptor =
        [[CDTCookieInterceptor alloc] initWithUsername:@"username" password:@"password"];

    // override the NSURLSession so we can stub the responses
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.protocolClasses = @[ [CookieResponseURLProtocol class] ];
    interceptor.urlSession = [NSURLSession sessionWithConfiguration:config];

    // create a context with a request which we can use
    NSURL *url = [NSURL URLWithString:@"http://username.cloudant.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    CDTHTTPInterceptorContext *context =
        [[CDTHTTPInterceptorContext alloc] initWithRequest:[request mutableCopy]];

    context = [interceptor interceptRequestInContext:context];

    XCTAssertEqualObjects(interceptor.cookie, expectedCookieString);
    XCTAssertEqual(interceptor.shouldMakeCookieRequest, YES);
    XCTAssertEqualObjects([context.request valueForHTTPHeaderField:@"Cookie"],
                          expectedCookieString);
}

- (void)testCookieInterceptorHandles401
{
    CDTCookieInterceptor *interceptor =
        [[CDTCookieInterceptor alloc] initWithUsername:@"username" password:@"password"];

    // override the NSURLSession so we can stub the responses
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.protocolClasses = @[ [Always401UrlProtocol class] ];
    interceptor.urlSession = [NSURLSession sessionWithConfiguration:config];

    // create a context with a request which we can use
    NSURL *url = [NSURL URLWithString:@"http://username.cloudant.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    CDTHTTPInterceptorContext *context =
        [[CDTHTTPInterceptorContext alloc] initWithRequest:[request mutableCopy]];

    context = [interceptor interceptRequestInContext:context];

    XCTAssertNil(interceptor.cookie);
    XCTAssertEqual(interceptor.shouldMakeCookieRequest, NO);
    XCTAssertNil([context.request valueForHTTPHeaderField:@"Cookie"]);
}

@end
