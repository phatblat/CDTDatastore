//
//  CDTCachingDatastoreTests.m
//  ReplicationAcceptance
//
//  Created by tomblench on 10/02/2015.
//
//

#import <XCTest/XCTest.h>

#import <CloudantSync.h>
#import <UNIRest.h>
#import <TRVSMonitor.h>

#import "CloudantReplicationBase.h"
#import "CloudantReplicationBase+CompareDb.h"
#import "ReplicationAcceptance+CRUD.h"
#import "ReplicatorDelegates.h"
#import "ReplicatorURLProtocol.h"
#import "ReplicatorURLProtocolTester.h"

#import "CDTDatastoreManager.h"
#import "CDTDatastore.h"
#import "CDTDocumentBody.h"
#import "CDTDocumentRevision.h"
#import "CDTPullReplication.h"
#import "CDTPushReplication.h"
#import "TDReplicatorManager.h"
#import "TDReplicator.h"
#import "CDTReplicator.h"
#import "CDTPullerByDocId.h"
#import "CDTCachingDatastore.h"

@interface CDTCachingDatastoreTests : CloudantReplicationBase

@property (nonatomic, strong) CDTDatastore *datastore;
@property (nonatomic, strong) CDTReplicatorFactory *replicatorFactory;

@property (nonatomic, strong) NSURL *primaryRemoteDatabaseURL;

/** This database is used as the primary remote database. Some tests create further
 databases, but all use this one.
 */
@property (nonatomic, strong) NSString *primaryRemoteDatabaseName;

@end

@implementation CDTCachingDatastoreTests

- (void)setUp
{
    [super setUp];
    
    // Create local and remote databases, start the replicator
    
    NSError *error;
    self.datastore = [self.factory datastoreNamed:@"test" error:&error];
    XCTAssertNotNil(self.datastore, @"datastore is nil");
    
    self.primaryRemoteDatabaseName = [NSString stringWithFormat:@"%@-test-database-%@",
                                      self.remoteDbPrefix,
                                      [CloudantReplicationBase generateRandomString:5]];
    self.primaryRemoteDatabaseURL = [self.remoteRootURL URLByAppendingPathComponent:self.primaryRemoteDatabaseName];
    [self createRemoteDatabase:self.primaryRemoteDatabaseName instanceURL:self.remoteRootURL];
    
    self.replicatorFactory = [[CDTReplicatorFactory alloc] initWithDatastoreManager:self.factory];
    
}

- (void) testCacheSomeDocuments
{
    // create some docs remotely
    CDTCachingDatastore *ds = [[CDTCachingDatastore alloc] initWithDatastore:self.datastore andRemoteDatabase:self.remoteRootURL];
    // do a get which will pull the doc back
    XCTAssertNotNil(ds);
    
}

- (void) testReplicateSubset
{
    
}

@end