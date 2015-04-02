//
//  CDTSecurityManager.m
//
//
//  Created by Enrique de la Torre Fernandez on 20/03/2015.
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

#import "CDTSecurityManager.h"

#import "CDTSecurityUtils.h"
#import "CDTSecurityKeychainStorage.h"
#import "CDTSecurityConstants.h"

#import "CDTLogging.h"

@interface CDTSecurityManager ()

@end

@implementation CDTSecurityManager

#pragma mark - Public methods
- (NSString *)getDPK:(NSString *)password
{
    CDTSecurityData *data =
        [[CDTSecurityKeychainStorage keychainStorage] encryptionKeyData];

    if (data == nil) {
        return nil;
    }

    NSString *pwKey = [self passwordToKey:password withSalt:data.salt];
    NSString *decryptedKey = [[CDTSecurityUtils util] decryptWithKey:pwKey
                                                      withCipherText:data.encryptedDPK
                                                              withIV:data.IV
                                                 checkBase64Encoding:YES];

    return decryptedKey;
}

- (BOOL)generateAndStoreDpkUsingPassword:(NSString *)password withSalt:(NSString *)salt
{
    NSString *hexEncodedDpk = [[CDTSecurityUtils util]
        generateRandomStringWithBytes:CDTDATASTORE_SECURITY_DEFAULT_DPK_SIZE];

    BOOL worked = [self storeDPK:hexEncodedDpk usingPassword:password withSalt:salt];

    return worked;
}

- (BOOL)isKeyChainFullyPopulated
{
    if ([[CDTSecurityKeychainStorage keychainStorage] areThereEncryptionKeyData]) {
        return YES;
    }

    return NO;
}

- (BOOL)clearKeyChain
{
    return [[CDTSecurityKeychainStorage keychainStorage] clearEncryptionKeyData];
}

#pragma mark - Private methods
- (BOOL)storeDPK:(NSString *)dpk usingPassword:(NSString *)password withSalt:(NSString *)salt
{
    

    NSString *pwKey = [self passwordToKey:password withSalt:salt];

    NSString *hexEncodedIv = [[CDTSecurityUtils util]
        generateRandomStringWithBytes:CDTDATASTORE_SECURITY_DEFAULT_IV_SIZE];

    NSString *encyptedDPK =
        [[CDTSecurityUtils util] encryptWithKey:pwKey withText:dpk withIV:hexEncodedIv];

    CDTSecurityData *data = [[CDTSecurityData alloc] init];
    data.IV = hexEncodedIv;
    data.salt = salt;
    data.encryptedDPK = encyptedDPK;
    data.iterations =[NSNumber numberWithInt:CDTDATASTORE_SECURITY_DEFAULT_PBKDF2_ITERATIONS];
    data.version = CDTDATASTORE_SECURITY_KEY_VERSION_NUMBER;
    
    BOOL worked = [[CDTSecurityKeychainStorage keychainStorage] saveEncryptionKeyData:data];
    
    return worked;
}

- (NSString *)passwordToKey:(NSString *)password withSalt:(NSString *)salt
{
    return [[CDTSecurityUtils util]
        generateKeyWithPassword:password
                        andSalt:salt
                  andIterations:CDTDATASTORE_SECURITY_DEFAULT_PBKDF2_ITERATIONS];
}

@end
