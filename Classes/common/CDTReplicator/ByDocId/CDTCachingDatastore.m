//
//  CDTCachingDatastore.m
//  
//
//  Created by Michael Rhodes on 29/01/2015.
//
//

#import "CDTCachingDatastore.h"

#import "CDTDatastore.h"
#import "CDTPullerByDocId.h"

@interface CDTCachingDatastore ()

@property (nonatomic,strong) CDTDatastore *datastore;
@property (nonatomic,strong) NSURL *remoteDatabase;

@end

@implementation CDTCachingDatastore

- (instancetype)initWithDatastore:(CDTDatastore*)datastore
                andRemoteDatabase:(NSURL*)remoteDatabase 
{
    self = [super init];
    if (self != nil) {
        _datastore = datastore;
        _remoteDatabase = remoteDatabase;
    }
    return self;
}

- (void)updateUsingDocIdsFromSet:(NSSet*)docIds
                   purgingOthers:(bool)purgeOthers
               completionHandler:(void(^) (NSError *error)) completionHandler
{
    void(^localCompletion) (NSError *error);
    localCompletion = [completionHandler copy];
    
    CDTPullerByDocId *p1 = [[CDTPullerByDocId alloc] initWithSource:self.remoteDatabase
                                                             target:self.datastore
                                                       docIdsToPull:[docIds allObjects]];
    p1.completionBlock = ^{
        localCompletion(nil);
    };
    
    [p1 start];
}

- (CDTDocumentRevision *)getDocumentWithId:(NSString *)docId
                                     error:(NSError *__autoreleasing *)error
{
    NSError *innerError;
    CDTDocumentRevision *rev = [self.datastore getDocumentWithId:docId
                                                           error:&innerError];
    
    if (rev == nil) {  // todo is error "not found"?
        
        BOOL timed_out = [self synchronouslyReplicateDocumentWithId:docId];
        
        if (!timed_out) {
            rev = [self.datastore getDocumentWithId:docId
                                              error:&innerError];
        }
    }
    
    return rev;
}

#pragma mark Helpers

/**
 Replicate a single document without purging others, return YES if completed within
 timeout.
 */
- (BOOL)synchronouslyReplicateDocumentWithId:(NSString*)docId
{
    dispatch_semaphore_t latch1 = dispatch_semaphore_create(0);
    [self updateUsingDocIdsFromSet:[NSSet setWithObjects:docId, nil]
                     purgingOthers:NO
                 completionHandler:^(NSError *error) {
                     dispatch_semaphore_signal(latch1);
                 }];
    dispatch_time_t wait_until = dispatch_walltime(DISPATCH_TIME_NOW, 600 * NSEC_PER_SEC);
    long value1 = dispatch_semaphore_wait(latch1, wait_until);
    BOOL timed_out = (value1 == 0);
    return timed_out;
}

@end
