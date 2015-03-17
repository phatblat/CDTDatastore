//
//  CDTDatastoreManager+EncryptionKey.h
//  
//
//  Created by Enrique de la Torre Fernandez on 10/03/2015.
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

#import "CDTDatastoreManager.h"

@protocol CDTEncryptionKeyProvider;

@interface CDTDatastoreManager (EncryptionKey)

/**
 Returns a datastore for the given name. If a key is provided, datastore files are encrypted before
 saving to disk (attachments and extensions not included).
 If a key is provided the first time the datastore is open, only this key will be valid the next
 time. In the same way, if no key is informed, the datastore will not be cipher and can not be
 cipher later on.
 
 @param name datastore name
 @param provider it returns the key to cipher the datastore
 @param error will point to an NSError object in case of error.
 
 @return a datastore for the given name

 @warning *Warning:* Encryption is an experimental feature, use with caution. It won't work unless
 you use subspec 'CDTDatastore/SQLCipher'
 
 @see CDTDatastore
 */
- (CDTDatastore *)datastoreNamed:(NSString *)name
       withEncryptionKeyProvider:(id<CDTEncryptionKeyProvider>)provider
                           error:(NSError *__autoreleasing *)error;

@end
