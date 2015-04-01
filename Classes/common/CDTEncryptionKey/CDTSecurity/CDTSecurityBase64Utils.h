//
//  CDTSecurityBase64Utils.h
//  
//
//  Created by Enrique de la Torre Fernandez on 01/04/2015.
//
//

#import <Foundation/Foundation.h>

@protocol CDTSecurityBase64Utils <NSObject>

- (NSString *)base64StringFromData:(NSData *)data length:(int)length isSafeUrl:(bool)isSafeUrl;
- (NSData *)base64DataFromString:(NSString *)string;
- (BOOL)isBase64Encoded:(NSString *)str;

@end
