//
//  CDTFetchChanges.m
//  
//
//  Created by Michael Rhodes on 31/03/2015.
//
//

#import "CDTFetchChanges.h"

#import "CDTDatastore.h"
#import "CDTDocumentRevision.h"

#import "TD_Database.h"

@implementation CDTFetchChanges

#pragma mark Initialisers

- (instancetype)initWithDatastore:(CDTDatastore *)datastore
        previousServerSequenceValue:(NSString *)previousServerSequenceValue
{
    self = [super init];
    if (self) {
        _datastore = datastore;
        _previousServerSequenceValue = [previousServerSequenceValue copy];
    }
    return self;
}

#pragma mark Instance methods

- (void)start
{
    CDTFetchChanges *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CDTFetchChanges *self = weakSelf;
        if (self) {
            [self syncStart]; 
        }
    });
}

- (void)syncStart
{
    TDChangesOptions options = {.limit = 500,
        .contentOptions = 0,                                
        .includeDocs = NO,  // we only need the docIDs and sequences, body is retrieved separately
        .includeConflicts = FALSE,
        .sortBySequence = TRUE};
    
    TD_RevisionList *changes;
    SequenceNumber lastSequence = [_previousServerSequenceValue longLongValue];
    
    do {
        changes = [[_datastore database] changesSinceSequence:lastSequence
                                                      options:&options
                                                       filter:nil
                                                       params:nil];
        lastSequence = [self notifyChanges:changes startingSequence:lastSequence];
    } while (changes.count > 0);
    
    if (self.fetchRecordChangesCompletionBlock) {
        self.fetchRecordChangesCompletionBlock([[NSNumber numberWithLongLong:lastSequence] stringValue], 
                                               _previousServerSequenceValue, 
                                               nil);
    }
}

/*
 Process a batch of changes and return the last sequence value in the changes.
 
 This method works out whether each change is an update/create or a delete, and calls
 the user-provided callback for each.
 
 @param changes changes come from the from the -changesSinceSequence:options:filter:params: call
 @param startingSequence the sequence value used for the list passed in `changes`.
            This is returned if no changes are processed.
 
 @return Last sequence number in the changes processed, used for the next _changes call.
 */
- (SequenceNumber)notifyChanges:(TD_RevisionList *)changes
               startingSequence:(SequenceNumber)startingSequence
{
    SequenceNumber lastSequence = startingSequence;
    
    // _changes provides the revs with highest rev ID, which might not be the
    // winning revision (e.g., tombstone on long doc branch). For all docs
    // that are updated rather than deleted, we need to be sure we index the
    // winning revision. This loop gets those revisions.
    NSMutableDictionary *updatedRevisions = [NSMutableDictionary dictionary];
    for (CDTDocumentRevision *rev in [_datastore getDocumentsWithIds:[changes allDocIDs]]) {
        if (rev != nil && !rev.deleted) {
            updatedRevisions[rev.docId] = rev;
        }
    }
    
    for (TD_Revision *change in changes) {
        
        CDTDocumentRevision *updatedRevision;
        if ((updatedRevision = updatedRevisions[change.docID]) != nil) {
            if (self.documentChangedBlock) {
                self.documentChangedBlock(updatedRevision);
            }
        } else {
            if (self.documentWithIDWasDeletedBlock) {
                self.documentWithIDWasDeletedBlock(change.docID);
            }
        }
        
        lastSequence = change.sequence;
    }
    
    return lastSequence;
}


@end
