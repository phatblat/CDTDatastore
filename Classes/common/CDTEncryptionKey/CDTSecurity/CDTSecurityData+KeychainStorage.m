//
//  CDTSecurityData+KeychainStorage.m
//
//
//  Created by Enrique de la Torre Fernandez on 02/04/2015.
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

#import "CDTSecurityData+KeychainStorage.h"

NSString *const CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_DPK = @"dpk";
NSString *const CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_SALT = @"jsonSalt";
NSString *const CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_IV = @"iv";
NSString *const CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_ITERATIONS = @"iterations";
NSString *const CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_VERSION = @"version";

@implementation CDTSecurityData (KeychainStorage)

#pragma mark - Public methods
- (NSDictionary *)dictionary
{
    NSAssert(self.encryptedDPK, @"Encrypted DPK not informed");
    NSAssert(self.salt, @"Salt not informed");
    NSAssert(self.IV, @"IV not informed");
    NSAssert(self.iterations, @"Iterations not informed");
    NSAssert(self.version, @"Version not informed");

    NSDictionary *dic = @{
        CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_DPK : self.encryptedDPK,
        CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_SALT : self.salt,
        CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_IV : self.IV,
        CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_ITERATIONS : self.iterations,
        CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_VERSION : self.version
    };

    return dic;
}

#pragma mark - Public class methods
+ (instancetype)securityDataWithDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert(dictionary);
    
    NSString *encryptedDPK = dictionary[CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_DPK];
    NSAssert(encryptedDPK, @"Encrypted DPK not informed");
    
    NSString *salt = dictionary[CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_SALT];
    NSAssert(salt, @"Salt not informed");
    
    NSString *IV = dictionary[CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_IV];
    NSAssert(IV, @"IV not informed");
    
    NSNumber *iterations = dictionary[CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_ITERATIONS];
    NSAssert(iterations, @"Iterations not informed");
    
    NSString *version = dictionary[CDTSECURITYDATA_KEYCHAINSTORAGE_KEY_VERSION];
    NSAssert(version, @"Version not informed");
    
    CDTSecurityData *data = [[[self class] alloc] init];
    data.encryptedDPK = encryptedDPK;
    data.salt = salt;
    data.IV = IV;
    data.iterations = iterations;
    data.version = version;
    
    return data;
}

@end
