//
//  CDTSecurityBase64UtilsTests.m
//  Tests
//
//  Created by Enrique de la Torre Fernandez on 01/04/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "CDTSecurityCustomBase64Utils.h"
#import "CDTSecurityAppleBase64Utils.h"

@interface CDTSecurityBase64UtilsTests : XCTestCase

@property (strong, nonatomic) CDTSecurityCustomBase64Utils *customUtils;
@property (strong, nonatomic) CDTSecurityAppleBase64Utils *appleUtils;

@end

@implementation CDTSecurityBase64UtilsTests

- (void)setUp
{
    [super setUp];

    // Put setup code here. This method is called before the invocation of each test method in the
    // class.
    self.customUtils = [[CDTSecurityCustomBase64Utils alloc] init];
    self.appleUtils = [[CDTSecurityAppleBase64Utils alloc] init];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.
    self.customUtils = nil;
    self.appleUtils = nil;

    [super tearDown];
}

- (void)testBase64StringFromDataReturnsSameValueInBothCases
{
    NSString *unicodeTxt = @"摇噺摃䈰婘栰";
    NSData *data = [unicodeTxt dataUsingEncoding:NSUTF8StringEncoding];

    NSString *base64 =
        [self.customUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    NSString *appleBase64 =
        [self.appleUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];

    XCTAssertEqualObjects(base64, appleBase64, @"Not the same result");
}

- (void)testBase64StringFromDataReturnsSameValueInBothCases02
{
    NSString *unicodeTxt = @"1234567890";
    NSData *data = [unicodeTxt dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *base64 =
    [self.customUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    NSString *appleBase64 =
    [self.appleUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    
    XCTAssertEqualObjects(base64, appleBase64, @"Not the same result");
}

- (void)testBase64StringFromDataReturnsSameValueInBothCases03
{
    NSString *unicodeTxt = @"a1s2d3f4g5";
    NSData *data = [unicodeTxt dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *base64 =
    [self.customUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    NSString *appleBase64 =
    [self.appleUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    
    XCTAssertEqualObjects(base64, appleBase64, @"Not the same result");
}

- (void)testBase64StringFromDataReturnsSameValueInBothCases04
{
    NSString *unicodeTxt = @"摇;摃:§婘栰";
    NSData *data = [unicodeTxt dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *base64 =
    [self.customUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    NSString *appleBase64 =
    [self.appleUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    
    XCTAssertEqualObjects(base64, appleBase64, @"Not the same result");
}

- (void)testBase64StringFromDataReturnsSameValueInBothCases05
{
    NSString *unicodeTxt = @"摇;摃:xx👹⌚️👽";
    NSData *data = [unicodeTxt dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *base64 =
    [self.customUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    NSString *appleBase64 =
    [self.appleUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];
    
    XCTAssertEqualObjects(base64, appleBase64, @"Not the same result");
}

- (void)testCustomBase64DataFromStringReturnsEmptyIfStringIsUnicde
{
    NSString *unicodeTxt = @"摇噺摃䈰婘栰";

    NSData *data = [self.customUtils base64DataFromString:unicodeTxt];
    
    XCTAssertTrue([data length] == 0, @"Do not work with unicode");
}

- (void)testAppleBase64DataFromStringDoesNotReturnEmptyIfStringIsUnicde
{
    NSString *unicodeTxt = @"摇噺摃䈰婘栰";
    
    NSData *appleData = [self.appleUtils base64DataFromString:unicodeTxt];
    
    XCTAssertTrue([appleData length] > 0, @"Work with unicode");
}

- (void)testIsBase64EncodedValidatesEachOtherResult
{
    NSString *unicodeTxt = @"摇噺摃䈰婘栰";
    NSData *data = [unicodeTxt dataUsingEncoding:NSUTF8StringEncoding];

    NSString *appleBase64 =
        [self.appleUtils base64StringFromData:data length:(int)[unicodeTxt length] isSafeUrl:NO];

    XCTAssertTrue([self.customUtils isBase64Encoded:appleBase64] &&
                      [self.appleUtils isBase64Encoded:appleBase64],
                  @"Not mutually compatible");
}

- (void)testbase64StringFromData
{
    NSString *txt = @"1234567890";
    NSData *data = [txt dataUsingEncoding:NSUTF8StringEncoding];
    int txtLength = (int)[txt length];
    
    NSString *base64 = [self.customUtils base64StringFromData:data length:txtLength isSafeUrl:NO];
    NSLog(@"\n\n<%@> -> <%@>\n\n", txt, base64);
    
    txt = @"a1s2d3f4g5";
    data = [txt dataUsingEncoding:NSUTF8StringEncoding];
    txtLength = (int)[txt length];
    
    base64 = [self.customUtils base64StringFromData:data length:txtLength isSafeUrl:NO];
    NSLog(@"\n\n<%@> -> <%@>\n\n", txt, base64);
    
    txt = @"摇噺摃䈰婘栰";
    data = [txt dataUsingEncoding:NSUTF8StringEncoding];
    txtLength = (int)[txt length];
    
    base64 = [self.customUtils base64StringFromData:data length:txtLength isSafeUrl:NO];
    NSLog(@"\n\n<%@> -> <%@>\n\n", txt, base64);
    
    txt = @"摇;摃:§婘栰";
    data = [txt dataUsingEncoding:NSUTF8StringEncoding];
    txtLength = (int)[txt length];
    
    base64 = [self.customUtils base64StringFromData:data length:txtLength isSafeUrl:NO];
    NSLog(@"\n\n<%@> -> <%@>\n\n", txt, base64);
    
    txt = @"摇;摃:xx👹⌚️👽";
    data = [txt dataUsingEncoding:NSUTF8StringEncoding];
    txtLength = (int)[txt length];
    
    base64 = [self.appleUtils base64StringFromData:data length:txtLength isSafeUrl:NO];
    NSLog(@"\n\n<%@> -> <%@>\n\n", txt, base64);
}

@end
