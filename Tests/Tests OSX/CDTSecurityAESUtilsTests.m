//
//  CDTSecurityAESUtilsTests.m
//  Tests
//
//  Created by Enrique de la Torre Fernandez on 01/04/2015.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "CDTSecurityCustomAESUtils.h"
#import "CDTSecurityAppleAESUtils.h"

#import "CDTSecurityUtils.h"
#import "CDTSecurityConstants.h"

@interface CDTSecurityAESUtilsTests : XCTestCase

@property (strong, nonatomic) CDTSecurityCustomAESUtils *customUtils;
@property (strong, nonatomic) CDTSecurityAppleAESUtils *appleUtils;

@property (strong, nonatomic) NSString *defaultKey;
@property (strong, nonatomic) NSString *defaultIV;

@property (strong, nonatomic) NSData *dataToEncrypt;
@property (strong, nonatomic) NSData *dataToDecrypt;

@end

@implementation CDTSecurityAESUtilsTests

- (void)setUp
{
    [super setUp];

    // Put setup code here. This method is called before the invocation of each test method in the
    // class.
    self.customUtils = [[CDTSecurityCustomAESUtils alloc] init];
    self.appleUtils = [[CDTSecurityAppleAESUtils alloc] init];

    CDTSecurityUtils *util = [CDTSecurityUtils util];
    self.defaultKey = [util generateRandomStringWithBytes:CDTDATASTORE_SECURITY_DEFAULT_DPK_SIZE];
    self.defaultIV = [util generateRandomStringWithBytes:CDTDATASTORE_SECURITY_DEFAULT_IV_SIZE];

    NSString *unicodeTxt = @"摇噺摃䈰婘栰";
    self.dataToEncrypt = [unicodeTxt dataUsingEncoding:NSUnicodeStringEncoding];
    self.dataToDecrypt =
        [self.appleUtils doEncrypt:self.dataToEncrypt key:self.defaultKey withIV:self.defaultIV];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.
    self.customUtils = nil;
    self.appleUtils = nil;

    self.defaultKey = nil;
    self.defaultIV = nil;

    self.dataToEncrypt = nil;
    self.dataToDecrypt = nil;

    [super tearDown];
}

- (void)testCustomDoEncryptDoNotFail
{
    NSData *data =
        [self.customUtils doEncrypt:self.dataToEncrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertNotNil(data, @"It should work");
}

- (void)testAppleDoEncryptDoNotFail
{
    NSData *data =
        [self.appleUtils doEncrypt:self.dataToEncrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertNotNil(data, @"It should work");
}

- (void)testDoEncryptReturnsSameResultInBothCases
{
    NSData *customData =
        [self.customUtils doEncrypt:self.dataToEncrypt key:self.defaultKey withIV:self.defaultIV];
    NSData *appleData =
        [self.appleUtils doEncrypt:self.dataToEncrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertEqualObjects(customData, appleData, @"Both objects should be equal");
}

- (void)testCustomDoDecryptDoNotFail
{
    NSData *data =
        [self.customUtils doDecrypt:self.dataToDecrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertNotNil(data, @"It should work");
}

- (void)testCustomDoDecryptReturnsExpectedValue
{
    NSData *data =
        [self.customUtils doDecrypt:self.dataToDecrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertEqualObjects(data, self.dataToEncrypt, @"Both objects should be equal");
}

- (void)testAppleDoDecryptDoNotFail
{
    NSData *data =
        [self.appleUtils doDecrypt:self.dataToDecrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertNotNil(data, @"It should work");
}

- (void)testAppleDoDecryptReturnsExpectedValue
{
    NSData *data =
        [self.appleUtils doDecrypt:self.dataToDecrypt key:self.defaultKey withIV:self.defaultIV];

    XCTAssertEqualObjects(data, self.dataToEncrypt, @"Both objects should be equal");
}

@end
