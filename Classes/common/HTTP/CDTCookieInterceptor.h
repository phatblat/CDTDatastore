//
//  CDTCookieInterceptor.h
//
//
//  Created by Rhys Short on 08/09/2015.
//
//

#import <Foundation/Foundation.h>
#import "CDTHTTPInterceptor.h"
#import "CDTMacros.h"

@interface CDTCookieInterceptor : NSObject <CDTHTTPInterceptor>

- (nullable instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithUsername:(nonnull NSString*)username
                                 password:(nonnull NSString*)password NS_DESIGNATED_INITIALIZER;

@end
