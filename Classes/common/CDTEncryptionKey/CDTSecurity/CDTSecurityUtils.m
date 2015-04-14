//
//  CDTSecurityUtils.m
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

#import "CDTSecurityUtils.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

#import "CDTSecurityConstants.h"
#import "CDTSecurityCustomBase64Utils.h"
#import "CDTSecurityCustomAESUtils.h"

@interface CDTSecurityUtils ()

@property (strong, nonatomic, readonly) id<CDTSecurityBase64Utils> base64Utils;
@property (strong, nonatomic, readonly) id<CDTSecurityAESUtils> aesUtils;

@end

@implementation CDTSecurityUtils

#pragma mark - Init object
- (instancetype)init
{
    return [self initWithBase64Utils:[[CDTSecurityCustomBase64Utils alloc] init]
                            aesUtils:[[CDTSecurityCustomAESUtils alloc] init]];
}

- (instancetype)initWithBase64Utils:(id<CDTSecurityBase64Utils>)base64Utils
                           aesUtils:(id<CDTSecurityAESUtils>)aesUtils;
{
    NSAssert(base64Utils, @"Base64 util is mandatory");
    NSAssert(aesUtils, @"AES util is mandatory");

    self = [super init];
    if (self) {
        _base64Utils = base64Utils;
        _aesUtils = aesUtils;
    }

    return self;
}

#pragma mark - Public class methods
- (NSString *)generateRandomStringWithBytes:(int)bytes
{
    uint8_t randBytes[bytes];

    int rc = SecRandomCopyBytes(kSecRandomDefault, (size_t)bytes, randBytes);
    if (rc != 0) {
        return nil;
    }

    NSMutableString *hexEncoded = [NSMutableString new];
    for (int i = 0; i < bytes; i++) {
        [hexEncoded appendString:[NSString stringWithFormat:@"%02x", randBytes[i]]];
    }

    NSString *randomStr = [NSString stringWithFormat:@"%@", hexEncoded];

    return randomStr;
}

- (NSString *)encryptWithKey:(NSString *)key withText:(NSString *)text withIV:(NSString *)iv
{
    if (![text isKindOfClass:[NSString class]] || [text length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_ENCRYPT
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_TEXT];
    }

    if (![key isKindOfClass:[NSString class]] || [key length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_ENCRYPT
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_KEY];
    }

    if (![iv isKindOfClass:[NSString class]] || [iv length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_ENCRYPT
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_IV];
    }

    NSData *dat = [text dataUsingEncoding:NSUnicodeStringEncoding];
    NSData *cipherDat = [self.aesUtils doEncrypt:dat key:key withIV:iv];

    NSString *encodedBase64CipherString =
        [self.base64Utils base64StringFromData:cipherDat length:(int)text.length isSafeUrl:NO];

    return encodedBase64CipherString;
}

- (NSString *)decryptWithKey:(NSString *)key
              withCipherText:(NSString *)ciphertext
                      withIV:(NSString *)iv
         checkBase64Encoding:(BOOL)checkBase64Encoding
{
    if (![ciphertext isKindOfClass:[NSString class]] || [ciphertext length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_DECRYPT
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_CIPHER];
    }

    if (![key isKindOfClass:[NSString class]] || [key length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_DECRYPT
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_KEY];
    }

    if (![iv isKindOfClass:[NSString class]] || [iv length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_DECRYPT
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_IV];
    }

    NSData *ciphertextEncoded = [self.base64Utils base64DataFromString:ciphertext];
    NSData *decodedCipher = [self.aesUtils doDecrypt:ciphertextEncoded key:key withIV:iv];

    NSString *returnText =
        [[NSString alloc] initWithData:decodedCipher encoding:NSUnicodeStringEncoding];

    if (returnText != nil) {
        if (checkBase64Encoding && ![self.base64Utils isBase64Encoded:returnText]) {
            returnText = nil;
        }
    }

    return returnText;
}

- (NSString *)generateKeyWithPassword:(NSString *)pass
                              andSalt:(NSString *)salt
                        andIterations:(NSInteger)iterations
{
    if (iterations < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_KEYGEN
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_INVALID_ITERATIONS];
    }

    if (![pass isKindOfClass:[NSString class]] || [pass length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_KEYGEN
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_PASSWORD];
    }

    if (![salt isKindOfClass:[NSString class]] || [salt length] < 1) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_KEYGEN
                    format:@"%@", CDTDATASTORE_SECURITY_ERROR_MSG_EMPTY_SALT];
    }

    NSData *passData = [pass dataUsingEncoding:NSUTF8StringEncoding];
    NSData *saltData = [salt dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *derivedKey = [NSMutableData dataWithLength:kCCKeySizeAES256];

#warning passwordLen is the length of the text password in BYTES
#warning pass.length is not the length in bytes, it is the number of characters
    int retVal = CCKeyDerivationPBKDF(kCCPBKDF2, passData.bytes, passData.length, saltData.bytes,
                                      salt.length, kCCPRFHmacAlgSHA1, (int)iterations,
                                      derivedKey.mutableBytes, kCCKeySizeAES256);

    if (retVal != kCCSuccess) {
        [NSException raise:CDTDATASTORE_SECURITY_ERROR_LABEL_KEYGEN
                    format:@"Return value: %d", retVal];
    }

    NSMutableString *derivedKeyStr = [NSMutableString stringWithCapacity:kCCKeySizeAES256 * 2];
    const unsigned char *dataBytes = [derivedKey bytes];

    for (int idx = 0; idx < kCCKeySizeAES256; idx++) {
        [derivedKeyStr appendFormat:@"%02x", dataBytes[idx]];
    }

    derivedKey = nil;
    dataBytes = nil;

    return [NSString stringWithString:derivedKeyStr];
}

#pragma mark - Public class methods
+ (instancetype)util { return [[[self class] alloc] init]; }

+ (instancetype)utilWithBase64Utils:(id<CDTSecurityBase64Utils>)base64Utils
                           aesUtils:(id<CDTSecurityAESUtils>)aesUtils
{
    return [[[self class] alloc] initWithBase64Utils:base64Utils aesUtils:aesUtils];
}

@end
