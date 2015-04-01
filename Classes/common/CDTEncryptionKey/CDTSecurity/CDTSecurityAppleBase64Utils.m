//
//  CDTSecurityAppleBase64Utils.m
//  
//
//  Created by Enrique de la Torre Fernandez on 01/04/2015.
//
//

#import "CDTSecurityAppleBase64Utils.h"

#import "CDTSecurityConstants.h"

#import "CDTLogging.h"

@implementation CDTSecurityAppleBase64Utils

#pragma mark - CDTSecurityBase64Utils methods
- (NSString *)base64StringFromData:(NSData *)data length:(int)length isSafeUrl:(bool)isSafeUrl
{
    CFErrorRef error = NULL;
    SecTransformRef transform = SecEncodeTransformCreate(kSecBase64Encoding, &error);
    if (error) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Error: %@", (NSError *)CFBridgingRelease(error));
        
        return nil;
    }
    
    NSData *transformedData = [CDTSecurityAppleBase64Utils transformData:data with:transform];
    
    CFRelease(transform);
    
    return [[NSString alloc] initWithData:transformedData encoding:NSUTF8StringEncoding];
}

- (NSData *)base64DataFromString:(NSString *)string
{
    CFErrorRef error = NULL;
    SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
    if (error) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Error: %@", (NSError *)CFBridgingRelease(error));
        
        return nil;
    }
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *transformedData = [CDTSecurityAppleBase64Utils transformData:data with:transform];
    
    CFRelease(transform);
    
    return transformedData;
}

- (BOOL)isBase64Encoded:(NSString *)str
{
    NSString *pattern =
    [[NSString alloc] initWithFormat:CDTDATASTORE_SECURITY_BASE64_REGEX, [str length]];
    
    NSError *error = NULL;
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSUInteger numMatch =
    [regex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
    if (numMatch != 1 || [error code] != 0) {
        return NO;
    }
    return YES;
}

#pragma mark - Private class methods: Base64
+ (NSData *)transformData:(NSData *)data with:(SecTransformRef)transform
{
    CFErrorRef error = NULL;
    SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFTypeRef)(data), &error);
    if (error) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Error: %@", (NSError *)CFBridgingRelease(error));
        
        return nil;
    }
    
    NSData *output = (NSData *)CFBridgingRelease(SecTransformExecute(transform, &error));
    if (error) {
        CDTLogError(CDTDATASTORE_LOG_CONTEXT, @"Error: %@", (NSError *)CFBridgingRelease(error));
        
        return nil;
    }
    
    return output;
}

@end
