//
//  IndexManagerEncryptionTests.m
//  EncryptionTests
//
//  Created by Enrique de la Torre Fernandez on 23/02/2015.
//  Copyright (c) 2015 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <XCTest/XCTest.h>

#import "CloudantSyncTests.h"
#import "CloudantTests+EncryptionTests.h"
#import "CDTDatastoreManager+EncryptionKey.h"
#import "CDTEncryptionKeyNilProvider.h"
#import "CDTHelperFixedKeyProvider.h"
#import "TD_Database.h"

#import "CDTIndexManager.h"

@interface IndexManagerEncryptionTests : CloudantSyncTests

@end

@implementation IndexManagerEncryptionTests

- (void)setUp
{
    [super setUp];

    // Put setup code here. This method is called before the invocation of each test method in the
    // class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.

    [super tearDown];
}

- (void)testCreateIndexManagerWithEncryptionKeyNilProvider
{
    CDTEncryptionKeyNilProvider *provider = [CDTEncryptionKeyNilProvider provider];
    CDTDatastore *datastore = [self.factory datastoreNamed:@"create_index_tests_nilprovider"
                                 withEncryptionKeyProvider:provider
                                                     error:nil];

    NSError *err = nil;
    CDTIndexManager *im = [[CDTIndexManager alloc] initWithDatastore:datastore error:&err];

    XCTAssertNotNil(im, @"indexManager is not nil");
    XCTAssertNil(err, @"error has to be nil");
}

- (void)testCreateIndexManagerWithEncryptionKeyNilProviderDoesNotCipherIndex
{
    // Create index
    CDTEncryptionKeyNilProvider *provider = [CDTEncryptionKeyNilProvider provider];
    CDTDatastore *datastore =
        [self.factory datastoreNamed:@"create_index_tests_nilprovider_notcipher"
            withEncryptionKeyProvider:provider
                                error:nil];

    __unused CDTIndexManager *im = [[CDTIndexManager alloc] initWithDatastore:datastore error:nil];

    // Check
    NSString *path = [CloudantSyncTests pathForIndexInDatastore:datastore];

    XCTAssertFalse([TD_Database isDatabaseEncryptedAtPath:path],
                   @"If no key is provided, index should not be encrypted");
}

- (void)testCreateIndexManagerWithFixedKeyProvider
{
    CDTHelperFixedKeyProvider *provider = [[CDTHelperFixedKeyProvider alloc] init];
    CDTDatastore *datastore = [self.factory datastoreNamed:@"create_index_tests_fixedprovider"
                                 withEncryptionKeyProvider:provider
                                                     error:nil];

    NSError *err = nil;
    CDTIndexManager *im = [[CDTIndexManager alloc] initWithDatastore:datastore error:&err];

    XCTAssertNotNil(im, @"indexManager is not nil");
    XCTAssertNil(err, @"error has to be nil");
}

- (void)testCreateIndexManagerWithFixedKeyProviderCiphersIndex
{
    // Create index
    CDTHelperFixedKeyProvider *provider = [[CDTHelperFixedKeyProvider alloc] init];
    CDTDatastore *datastore =
        [self.factory datastoreNamed:@"create_index_textests_mockprovider_cipher"
            withEncryptionKeyProvider:provider
                                error:nil];

    __unused CDTIndexManager *im = [[CDTIndexManager alloc] initWithDatastore:datastore error:nil];

    // Check
    NSString *path = [CloudantSyncTests pathForIndexInDatastore:datastore];

    XCTAssertTrue([TD_Database isDatabaseEncryptedAtPath:path],
                  @"If a key is provided, index has to be encrypted");
}

@end
