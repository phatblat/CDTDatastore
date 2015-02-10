//
//  CDTCachingDatastore.h
//  
//
//  Created by Michael Rhodes on 29/01/2015.
//
//

#import <Foundation/Foundation.h>

@class CDTDatastore;
@class CDTDocumentRevision;

/**
 CDTCachingDatastore wraps a CDTDatastore object to provide a caching, read-only datastore.
 
 CDTCachingDatastore is initialised with a CDTDatastore instance and a remote database
 URL. All remote operations are bound to the database passed during init.
 
 When a client calls -getDocumentById:(NSString*)docID, the datastore will return a local
 document if one exists, otherwise it will attempt to replicate the document from the 
 remote database, then pass that back. If neither a local nor remote copy exist, it will
 return `nil`. The local copy will be returned from then on, even if it is out of date
 with respect to the server.
 
 To update locally cached documents, use -updateUsingDocIdsFromSet:purgingOthers:completionHandler:.
 This will use replication to update all documents named in the passed set. If purgingOthers is
 YES, documents not present in the passed set will be purged from the database. Be sure that's
 what you want to happen. Purging documents is useful for creating local copies of the results
 of queries on the remote database.
 */
@interface CDTCachingDatastore : NSObject

- (instancetype)initWithDatastore:(CDTDatastore*)datastore
                andRemoteDatabase:(NSURL*)remoteDatabase;


- (void)updateUsingDocIdsFromSet:(NSSet*)docIds
                   purgingOthers:(bool)purgeOthers
               completionHandler:(void(^) (NSError *error)) completionHandler;

- (CDTDocumentRevision *)getDocumentWithId:(NSString *)docId
                                     error:(NSError *__autoreleasing *)error;


@end
