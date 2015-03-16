//
//  TD_DatabaseEncryptionTests.m
//  Tests
//
//  Created by Enrique de la Torre Fernandez on 20/02/2015.
//  Copyright (c) 2015 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <Foundation/Foundation.h>

#import "CloudantTests+EncryptionTests.h"
#import "CDTEncryptionKeyNilProvider.h"
#import "CDTHelperFixedKeyProvider.h"

#import "TD_Database.h"

@interface TD_DatabaseEncryptionTests : CloudantTests

@end

@implementation TD_DatabaseEncryptionTests

- (void)testCreateEmptyWithEncryptionKeyNilProviderDoesNotCipherDatabase
{
    // Create db
    CDTEncryptionKeyNilProvider *provider = [CDTEncryptionKeyNilProvider provider];

    NSString *path = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"TD_DatabaseEncryptionTests_NilNotCipher"];
    [TD_Database createEmptyDBAtPath:path withEncryptionKeyProvider:provider];

    // Check
    XCTAssertFalse([TD_Database isDatabaseEncryptedAtPath:path],
                   @"If no key is provided, db should not be encrypted");
}

- (void)testOpenWithoutEncryptionKeyThrowsException
{
    NSString *path =
        [NSTemporaryDirectory() stringByAppendingPathComponent:@"TD_DatabaseEncryptionTests"];

    TD_Database *db = [[TD_Database alloc] initWithPath:path];

    XCTAssertThrows([db openWithEncryptionKeyProvider:nil],
                    @"The key is mandatory. Inform a nil provider to not cipher the database");
}

- (void)testOpenFailsIfEncryptionKeyProviderReturnsAValue
{
    CDTHelperFixedKeyProvider *provider = [[CDTHelperFixedKeyProvider alloc] init];
    NSString *path = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"TD_DatabaseEncryptionTests_OpenFails"];

    TD_Database *db = [[TD_Database alloc] initWithPath:path];

    XCTAssertFalse([db openWithEncryptionKeyProvider:provider],
                   @"DB can't be opened with key because encription library is not available");
}

- (void)testOpenFailsIfEncryptionKeyProviderReturnsAValueWithANonEncryptedDatabase
{
    // Create non-encrypted db
    CDTEncryptionKeyNilProvider *nilProvider = [CDTEncryptionKeyNilProvider provider];

    NSString *path = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"TD_DatabaseEncryptionTests_nonEncryptDB"];
    [TD_Database createEmptyDBAtPath:path withEncryptionKeyProvider:nilProvider];

    // Reload db
    TD_Database *db = [[TD_Database alloc] initWithPath:path];

    // Open with fixed key provider
    CDTHelperFixedKeyProvider *fixedProvider = [[CDTHelperFixedKeyProvider alloc] init];

    XCTAssertFalse([db openWithEncryptionKeyProvider:fixedProvider],
                   @"A non-encrypted db can not be open with an encryption key");
}

- (void)testReopenWithoutEncryptionKeyThrowsException
{
    // Create non-encrypted db
    CDTEncryptionKeyNilProvider *nilProvider = [CDTEncryptionKeyNilProvider provider];

    NSString *path = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"TD_DatabaseEncryptionTests_reOpen"];
    TD_Database *db = [TD_Database createEmptyDBAtPath:path withEncryptionKeyProvider:nilProvider];

    // Re-open without provider
    XCTAssertThrows([db openWithEncryptionKeyProvider:nil],
                    @"The key is mandatory. Inform a nil provider to not cipher the database");
}

- (void)testReopenFailsIfEncryptionKeyProviderReturnsAValueWithANonEncryptedDatabase
{
    // Create non-encrypted db
    CDTEncryptionKeyNilProvider *nilProvider = [CDTEncryptionKeyNilProvider provider];

    NSString *path = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"TD_DatabaseEncryptionTests_reOpenNonEncryptDB"];
    TD_Database *db = [TD_Database createEmptyDBAtPath:path withEncryptionKeyProvider:nilProvider];

    // Re-open with fixed key provider
    CDTHelperFixedKeyProvider *fixedProvider = [[CDTHelperFixedKeyProvider alloc] init];

    XCTAssertFalse([db openWithEncryptionKeyProvider:fixedProvider],
                   @"A non-encrypted db can not be open with an encryption key");
}

@end
