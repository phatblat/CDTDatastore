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
#import "CDTSecurityData+KeychainStorage.h"
#import "CDTSecurityConstants.h"
#import "NSObject+CDTSecurityJSON.h"
#import "NSString+CDTSecurityJSON.h"

#import "CDTLogging.h"

@interface CDTSecurityManager ()

@end

@implementation CDTSecurityManager

#pragma mark - Public methods
- (NSString *)getDPK:(NSString *)password
{
    CDTSecurityData *data = [self getSecurityDataFromKeyChain];

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
    if ([self checkDpkDocumentIsInKeychain]) {
        return YES;
    }

    return NO;
}

- (BOOL)clearKeyChain
{
    BOOL worked = NO;

    NSMutableDictionary *dict = [self getDpkDocumentLookupDict];
    [dict removeObjectForKey:(__bridge id)(kSecReturnData)];
    [dict removeObjectForKey:(__bridge id)(kSecMatchLimit)];
    [dict removeObjectForKey:(__bridge id)(kSecReturnAttributes)];
    [dict removeObjectForKey:(__bridge id)(kSecAttrAccount)];

    OSStatus err = SecItemDelete((__bridge CFDictionaryRef)dict);

    if (err == noErr || err == errSecItemNotFound) {
        worked = YES;
    } else {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                   @"Error getting DPK doc from keychain, SecItemDelete returned: %d", (int)err);
    }

    return worked;
}

#pragma mark - Private methods
- (BOOL)storeDPK:(NSString *)dpk usingPassword:(NSString *)password withSalt:(NSString *)salt
{
    BOOL worked = NO;

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
    
    NSDictionary *jsonEntriesDict = [data dictionary];
    NSString *jsonStr = [jsonEntriesDict CDTSecurityJSONRepresentation];
    NSMutableDictionary *jsonDocStoreDict =
        [self getGenericPwStoreDict:CDTDATASTORE_SECURITY_KEY_DOCUMENT_ID data:jsonStr];

    OSStatus err = SecItemAdd((__bridge CFDictionaryRef)jsonDocStoreDict, nil);
    if (err == noErr) {
        worked = YES;
    } else if (err == errSecDuplicateItem) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"Doc already exists in keychain");
        worked = NO;
    } else {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                   @"Unable to store Doc in keychain, SecItemAdd returned: %d", (int)err);
        worked = NO;
    }

    return worked;
}

- (CDTSecurityData *)getSecurityDataFromKeyChain
{
    NSMutableDictionary *lookupDict = [self getDpkDocumentLookupDict];

    NSData *theData = nil;

    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)lookupDict, (void *)&theData);

    if (err == noErr) {
        NSString *jsonStr = [[NSString alloc] initWithBytes:[theData bytes]
                                                     length:[theData length]
                                                   encoding:NSUTF8StringEncoding];

        id jsonDoc = [jsonStr CDTSecurityJSONValue];

        if (jsonDoc != nil && [jsonDoc isKindOfClass:[NSDictionary class]]) {
            CDTSecurityData *data =
                [CDTSecurityData securityDataWithDictionary:(NSDictionary *)jsonDoc];

            // Ensure the num derivations saved, matches what we have
            int iters = [data.iterations intValue];

            if (iters != CDTDATASTORE_SECURITY_DEFAULT_PBKDF2_ITERATIONS) {
                CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                           @"Number of iterations stored, does NOT match the constant value %u",
                           CDTDATASTORE_SECURITY_DEFAULT_PBKDF2_ITERATIONS);
                return nil;
            }

            return data;
        }
    } else {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                   @"Error getting DPK doc from keychain, SecItemCopyMatching returned: %d",
                   (int)err);
    }

    return nil;
}

- (BOOL)checkDpkDocumentIsInKeychain
{
    NSData *dpkData = nil;

    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)[self getDpkDocumentLookupDict],
                                       (void *)&dpkData);

    if (err == noErr) {
        NSString *dpk = [[NSString alloc] initWithBytes:[dpkData bytes]
                                                 length:[dpkData length]
                                               encoding:NSUTF8StringEncoding];

        if (dpk != nil && [dpk length] > 0) {
            return YES;

        } else {
            // Found a match in keychain, but it was empty
            return NO;
        }

    } else if (err == errSecItemNotFound) {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT, @"DPK doc not found in keychain");

        return NO;
    } else {
        CDTLogWarn(CDTDATASTORE_LOG_CONTEXT,
                   @"Error getting DPK doc from keychain, SecItemCopyMatching returned: %d",
                   (int)err);

        return NO;
    }
}

- (NSString *)passwordToKey:(NSString *)password withSalt:(NSString *)salt
{
    return [[CDTSecurityUtils util]
        generateKeyWithPassword:password
                        andSalt:salt
                  andIterations:CDTDATASTORE_SECURITY_DEFAULT_PBKDF2_ITERATIONS];
}

- (NSMutableDictionary *)getDpkDocumentLookupDict
{
    NSMutableDictionary *dpkQuery =
        [self getGenericPwLookupDict:CDTDATASTORE_SECURITY_KEY_DOCUMENT_ID];
    return dpkQuery;
}

- (NSMutableDictionary *)getGenericPwLookupDict:(NSString *)identifier
{
    NSMutableDictionary *genericPasswordQuery = [[NSMutableDictionary alloc] init];
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                             forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:CDTDATASTORE_SECURITY_DEFAULT_ACCOUNT
                             forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [genericPasswordQuery setObject:identifier forKey:(__bridge id<NSCopying>)(kSecAttrService)];

    // Use the proper search constants, return only the attributes of the first match.
    [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne
                             forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    [genericPasswordQuery setObject:(__bridge id)kCFBooleanFalse
                             forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    [genericPasswordQuery setObject:(__bridge id)kCFBooleanTrue
                             forKey:(__bridge id<NSCopying>)(kSecReturnData)];
    return genericPasswordQuery;
}

- (NSMutableDictionary *)getGenericPwStoreDict:(NSString *)identifier data:(NSString *)theData
{
    NSMutableDictionary *genericPasswordQuery = [[NSMutableDictionary alloc] init];
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword
                             forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:CDTDATASTORE_SECURITY_DEFAULT_ACCOUNT
                             forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [genericPasswordQuery setObject:identifier forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [genericPasswordQuery setObject:[theData dataUsingEncoding:NSUTF8StringEncoding]
                             forKey:(__bridge id<NSCopying>)(kSecValueData)];
    [genericPasswordQuery setObject:(__bridge id)(kSecAttrAccessibleAlways)
                             forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];

    return genericPasswordQuery;
}

@end
