//
//  CDTSecurityKeychainStorage.m
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

#import "CDTSecurityKeychainStorage.h"

#import "CDTSecurityConstants.h"
#import "CDTSecurityData+KeychainStorage.h"
#import "NSString+CDTSecurityJSON.h"
#import "NSObject+CDTSecurityJSON.h"

#import "CDTLogging.h"

@interface CDTSecurityKeychainStorage ()

@end

@implementation CDTSecurityKeychainStorage

#pragma mark - Public methods
- (CDTSecurityData *)encryptionKeyData
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

- (BOOL)saveEncryptionKeyData:(CDTSecurityData *)data
{
    BOOL worked = NO;

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

- (BOOL)clearEncryptionKeyData
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

- (BOOL)areThereEncryptionKeyData
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

#pragma mark - Public class methods
+ (instancetype)keychainStorage { return [[[self class] alloc] init]; }

#pragma mark - Private methods
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
