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

- (void)testBase64DataFromStringReturnsSameValueInBothCasesIfStringIsNotUnicde
{
    NSString *simpleTxt = @"test text";

    NSData *data = [self.customUtils base64DataFromString:simpleTxt];
    NSData *appleData = [self.appleUtils base64DataFromString:simpleTxt];

    XCTAssertEqualObjects(data, appleData, @"Not the same result");
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

@end
