//
//  CDTPullerByDocId.m
//  
//
//  Created by Michael Rhodes on 14/01/2015.
//
//

#import "CDTPullerByDocId.h"

#import "CDTDatastore.h"
#import "CDTLogging.h"

#import "TDMultipartDownloader.h"
#import "TDMisc.h"
#import "TD_Database.h"
#import "TD_Database+Insertion.h"
#import "TDAuthorizer.h"
#import "TDJSON.h"

#import "ExceptionUtils.h"
#import "MYBlockUtils.h"

// Maximum number of revision IDs to pass in an "?atts_since=" query param (from TDPuller.m)
#define kMaxNumberOfAttsSince 50u

@interface CDTPullerByDocId ()

/** Set with doc Ids. Using a set ensures we don't do a doc twice. */
@property (nonatomic,strong) NSSet *docIdsToPull;

@property (nonatomic,strong) NSURL *source;

@property (nonatomic,strong) CDTDatastore *target;

@property (nonatomic,strong) TDBasicAuthorizer *authorizer;

@property (nonatomic,strong) NSDictionary *requestHeaders;

@property (nonatomic) NSUInteger changesProcessed;

@property (nonatomic) NSUInteger revisionsFailed;

@property (nonatomic,strong) NSError *error;

@property (nonatomic) NSUInteger asyncTaskCount;

@property (nonatomic) BOOL active;

@property (nonatomic, strong) NSThread *replicatorThread;

@property (nonatomic,strong) NSString *sessionID;

@end

@implementation CDTPullerByDocId



- (instancetype)initWithSource:(NSURL*)source
                       target:(CDTDatastore*)target
                 docIdsToPull:(NSArray*)docIdsToPull
{
    self = [super init];
    if (self) {
        _source = source;
        _target = target;
        _active = NO;
        _stopRunLoop = NO;
        
        _docIdsToPull = [NSSet setWithArray:docIdsToPull];
    }
    return self;
}

- (BOOL)start {
    if(_replicatorThread){
        return YES;  // already started
    }
    
    self.sessionID = @"not unique yet";
    
    _replicatorThread = [[NSThread alloc] initWithTarget: self
                                                selector: @selector(runReplicatorThread)
                                                  object: nil];
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"Starting TDReplicator thread %@ ...", _replicatorThread);
    [_replicatorThread start];
    
    __weak CDTPullerByDocId *weakSelf = self;
    [self queue:^{
        __strong CDTPullerByDocId *strongSelf = weakSelf;
        [strongSelf startReplicatorTasks];
    }];
    
    return YES;
}

- (void)queue:(void(^)())block {
    Assert(_replicatorThread, @"-queue: called after -stop");
    MYOnThread(_replicatorThread, block);
}


/**
 * Start a thread for each replicator
 * Taken from TDServer.m.
 */
- (void) runReplicatorThread {
    @autoreleasepool {
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"TDReplicator thread starting...");
        
        [[NSThread currentThread]
         setName:[NSString stringWithFormat:@"CDTPullerByDocId: %@", self.sessionID]];
        
#ifndef GNUSTEP
        // Add a no-op source so the runloop won't stop on its own:
        CFRunLoopSourceContext context = {}; // all zeros
        CFRunLoopSourceRef source = CFRunLoopSourceCreate(NULL, 0, &context);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        CFRelease(source);
#endif
        
        // Now run:
        while (!_stopRunLoop && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                                         beforeDate: [NSDate dateWithTimeIntervalSinceNow:0.1]])
            ;
        
        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"TDReplicator thread exiting");
    }
}

/** Assumes it's running on the replicator's thread, because all the networking code uses
 the current thread's runloop. */
-(BOOL)startReplicatorTasks
{
    // From TDReplicator
    // If client didn't set an authorizer, use basic auth if credential is available:
    if (!_authorizer) {
        _authorizer = [[TDBasicAuthorizer alloc] initWithURL:self.source];
        if (_authorizer) {
            CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@: Found credential, using %@", self, _authorizer);
        }
    }
    // END from TDReplicator
    
    // Add UA to request headers
    NSMutableDictionary* headers = $mdict({ @"User-Agent", [TDRemoteRequest userAgentHeader] });
    [headers addEntriesFromDictionary:_requestHeaders];
    self.requestHeaders = headers;
    
    // Sync for now
    for (NSString *docId in self.docIdsToPull) {
//        [self pullMissingRemoteRevisions:docId ignoreMissingDocs:YES immediatelyInsert:YES];
        [self pullRemoteRevision:docId ignoreMissingDocs:YES immediatelyInsert:YES];
//        [self pullRemoteRevision:docId ignoreMissingDocs:YES immediatelyInsert:YES];
    }
    return YES;
}
/*
- (void) pullMissingRemoteRevisions:(NSString*)docId
          ignoreMissingDocs:(BOOL)ignoreMissingDocs
          immediatelyInsert:(BOOL)immediatelyInsert
{
    [self asyncTaskStarted];

    
    TD_Database *_db = self.target.database;
    
    TD_RevisionList *localRevs = [_db getAllRevisionsOfDocumentID:docId onlyCurrent:NO excludeDeleted:NO];
    NSMutableArray *localRevsList = [NSMutableArray array];
    for (TD_Revision *localRev in localRevs) {
        [localRevsList addObject:localRev.revID];
    }
    NSDictionary *localRevsDict = @{docId: localRevsList};
    NSLog(@"Looking for docid %@ with revids %@\n", docId, localRevsList);
    __weak CDTPullerByDocId* weakSelf = self;
    
    
    
    
    [self sendAsyncRequest:@"GET"
                      path:[NSString stringWithFormat:@"%@?revs=true", docId]
                      body:nil
              onCompletion:^(NSDictionary* results, NSError* error) {
                  NSLog(@"Result for docid %@ with revids %@ is %@\n", docId, localRevsList, results);
                  __strong CDTPullerByDocId *strongSelf = weakSelf;
                  if (error) {
                      strongSelf.error = error;
                      [strongSelf revisionFailed];
                  } else if (results[@"_revisions"]) {
                      int start = [results[@"_revisions"][@"start"] intValue];
                      for (NSString *revId in results[@"_revisions"][@"ids"]) {
                          NSString *fullRevId = [NSString stringWithFormat:@"%d-%@", start--, revId];
                          NSLog(@"fetching %@ %@", docId, fullRevId);
                          // iterate through results and call pullRemoteRevision for each
                          [strongSelf pullRemoteRevision:docId revID:fullRevId ignoreMissingDocs:YES immediatelyInsert:YES];
                       }
                  } else {
                      NSLog(@"???");
                  }
                  [strongSelf asyncTasksFinished:1];
              }];
}
*/

/*  Fetches the contents of a revision from the remote db, including its parent revision ID.
    The contents are stored into rev.properties.
    Adapted from TDPuller.m 
 */
- (void) pullRemoteRevision:(NSString*)docId
          ignoreMissingDocs:(BOOL)ignoreMissingDocs
          immediatelyInsert:(BOOL)immediatelyInsert
{
    [self asyncTaskStarted];
//    ++_httpConnectionCount;
    
    // TODO: 'pullMissingRemoteRevisions' is a better name
    // - call revs_diff with the revids we have
    // - process through the list of missing revids and download them
    
    TD_Database *_db = self.target.database;
/*
    - (TD_RevisionList*)getAllRevisionsOfDocumentID:(NSString*)docID
onlyCurrent:(BOOL)onlyCurrent
excludeDeleted:(BOOL)excludeDeleted
database:(FMDatabase*)db
  */

    
    
    // Construct a query. We want the revision history, and the bodies of attachments that have
    // been added since the latest revisions we have locally.
    // See: http://wiki.apache.org/couchdb/HTTP_Document_API#GET
    // See: http://wiki.apache.org/couchdb/HTTP_Document_API#Getting_Attachments_With_a_Document
//    NSString* path = $sprintf(@"%@?revid=%@&attachments=true", TDEscapeID(docId), TDEscapeID(revId));
    NSString* path = $sprintf(@"%@?open_revs=all&revs=true", TDEscapeID(docId));
    /*
    TD_Revision *rev = [_db getDocumentWithID:docId revisionID:nil];
    
    // Use atts_since so we don't pull attachments that we should already have
    NSArray* knownRevs = [_db getPossibleAncestorRevisionIDs: rev limit: kMaxNumberOfAttsSince];
    if (knownRevs.count > 0) {
        path = [path stringByAppendingFormat:@"&atts_since=%@", joinQuotedEscaped(knownRevs)];
    }*/
    CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@: GET %@", self, path);
    
    // Under ARC, using variable dl directly in the block given as an argument to initWithURL:...
    // results in compiler error (could be undefined variable)
    __weak CDTPullerByDocId* weakSelf = self;
    TDRemoteJSONRequest* dl;
    dl = [[TDRemoteJSONRequest alloc] initWithMethod:@"GET"
                                                 URL:TDAppendToURL(self.source, path)
                                                body:nil
                                      requestHeaders:self.requestHeaders
                                        onCompletion:^(id result, NSError *error) {
              __strong CDTPullerByDocId *strongSelf = weakSelf;
              
              // OK, now we've got the response revision:
              if (error) {
                  
                  // TODO go through _revisions in this response and use our local revsDiff to figure out which revs are missing
                  
                  // if ignoreMissingDocs is true, we know that some requests might 404
                  if (!(ignoreMissingDocs && error.code == 404)) {
                      strongSelf.error = error;
                      [strongSelf revisionFailed];
                  }
                  strongSelf.changesProcessed++;
              } else {
                  TD_RevisionList *revs = [[TD_RevisionList alloc] init];
                  for (id rev in result) {
                      // TODO check if we have this rev already
                      [revs addRev:[TD_Revision revisionWithProperties:rev[@"ok"]]];
                  }
                  //gotRev.sequence = rev.sequence;
                  [strongSelf insertDownloads:[revs allRevisions]];  // increments changesProcessed
              }
              
              // Note that we've finished this task:
//              [strongSelf removeRemoteRequest:dl];
              [strongSelf asyncTasksFinished:1];
//              --_httpConnectionCount;
          }
          ];
//    [self addRemoteRequest: dl];
    dl.authorizer = _authorizer;
    [dl start];
}

/* Adapted from TDPuller.m */
static NSString* joinQuotedEscaped(NSArray* strings)
{
    if (strings.count == 0) return @"[]";
    NSString* json = [TDJSON stringWithJSONObject:strings options:0 error:NULL];
    return TDEscapeURLParam(json);
}

/* Adapted from TDPuller.m */
- (void)asyncTaskStarted
{
    if (_asyncTaskCount++ == 0) [self updateActive];
}

/* Adapted from TDPuller.m */
- (void)asyncTasksFinished:(NSUInteger)numTasks
{
    _asyncTaskCount -= numTasks;
    Assert(_asyncTaskCount >= 0);
    if (_asyncTaskCount == 0) {
        [self updateActive];
    }
}

/* Adapted from TDPuller.m */
- (void)updateActive
{
    BOOL active = _asyncTaskCount > 0;
    if (active != _active) {
        self.active = active;
//        [self postProgressChanged];
        if (!_active) {
            if (self.completionBlock) {
                self.completionBlock();
            }
            _stopRunLoop = YES;
            _replicatorThread = nil;
        }
    }
}



// This will be called when _downloadsToInsert fills up:
/* Adapted from TDPuller.m */
- (void)insertDownloads:(NSArray*)downloads
{
    CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@ inserting %u revisions...", self,
                  (unsigned)downloads.count);
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    
    TD_Database *_db = self.target.database;
    
    //    [_db beginTransaction];
    //    BOOL success = NO;
    @try {
        downloads = [downloads sortedArrayUsingSelector:@selector(compareSequences:)];
        for (TD_Revision* rev in downloads) {
            @autoreleasepool
            {
                NSArray* history = [TD_Database parseCouchDBRevisionHistory:rev.properties];
                if (!history && rev.generation > 1) {
                    CDTLogWarn(CDTREPLICATION_LOG_CONTEXT,
                               @"%@: Missing revision history in response for %@", self, rev);
                    self.error = TDStatusToNSError(kTDStatusUpstreamError, nil);
                    [self revisionFailed];
                    continue;
                }
                CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@ inserting %@ %@", self, rev.docID,
                              [history my_compactDescription]);
                
                // Insert the revision:
                int status = [_db forceInsert:rev revisionHistory:history source:self.source];
                if (TDStatusIsError(status)) {
                    if (status == kTDStatusForbidden)
                        CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: Remote rev failed validation: %@",
                                   self, rev);
                    else {
                        CDTLogWarn(CDTREPLICATION_LOG_CONTEXT, @"%@ failed to write %@: status=%d", self,
                                   rev, status);
                        [self revisionFailed];
                        self.error = TDStatusToNSError(status, nil);
                        continue;
                    }
                }
            }
        }
        
        CDTLogVerbose(CDTREPLICATION_LOG_CONTEXT, @"%@ finished inserting %u revisions", self,
                      (unsigned)downloads.count);
        
        //        success = YES;
    }
    @catch (NSException* x) { MYReportException(x, @"%@: Exception inserting revisions", self); }
    //    @finally {
    //        [_db endTransaction: success];
    //    }
    
    time = CFAbsoluteTimeGetCurrent() - time;
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@ inserted %u revs in %.3f sec (%.1f/sec)", self,
               (unsigned)downloads.count, time, downloads.count / time);
    
    self.changesProcessed += downloads.count;
//    [self asyncTasksFinished:downloads.count];
}

- (void)revisionFailed
{
    // Remember that some revisions failed to transfer, so we can later retry.
    ++_revisionsFailed;
}


// TODO this is cribbed from TDReplicator
- (TDRemoteJSONRequest*)sendAsyncRequest:(NSString*)method
                                    path:(NSString*)path
                                    body:(id)body
                            onCompletion:(TDRemoteRequestCompletionBlock)onCompletion
{
    CDTLogInfo(CDTREPLICATION_LOG_CONTEXT, @"%@: %@ %@", self, method, path);
    NSURL* url;
    if ([path hasPrefix:@"/"]) {
        url = [[NSURL URLWithString:path relativeToURL:_source] absoluteURL];
    } else {
        url = TDAppendToURL(_source, path);
    }
    onCompletion = [onCompletion copy];
    
    // under ARC, using variable req used directly inside the block results in a compiler error (it
    // could have undefined value).
    __weak CDTPullerByDocId* weakSelf = self;
    __block TDRemoteJSONRequest* req = nil;
    req = [[TDRemoteJSONRequest alloc] initWithMethod:method
                                                  URL:url
                                                 body:body
                                       requestHeaders:self.requestHeaders
                                         onCompletion:^(id result, NSError* error) {
                                             CDTPullerByDocId* strongSelf = weakSelf;
//                                             [strongSelf removeRemoteRequest:req];
                                             id<TDAuthorizer> auth = req.authorizer;
                                             if (auth && auth != _authorizer && error.code != 401) {
                                                 CDTLogInfo(CDTREPLICATION_LOG_CONTEXT,
                                                            @"%@: Updated to %@", self, auth);
                                                 _authorizer = auth;
                                             }
                                             onCompletion(result, error);
                                         }];
    req.authorizer = _authorizer;
//    [self addRemoteRequest:req];
    [req start];
    return req;
}

@end
