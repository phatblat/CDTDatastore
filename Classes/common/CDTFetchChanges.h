//
//  CDTFetchChanges.h
//  
//
//  Created by Michael Rhodes on 31/03/2015.
//
//

#import <Foundation/Foundation.h>

@class CDTDatastore;
@class CDTDocumentRevision;

/**
 Read changes to a database.
 
 CDTFetchChanges reads the changes to a database from a given sequence value. It provides
 callbacks for updated and created documents (documentChangedBlock) and deleted documents
 (documentWithIDWasDeletedBlock). It also provides a completion block for when all changes
 have been received and processed.
 
 The CDTFetchChanges object will always return _all_ changes from the given sequence value.
 
 The blocks you assign to process the fetched records are executed serially on an 
 internal queue managed by the operation. Your blocks must be capable of executing 
 on a background thread, so any tasks that require access to the main thread must 
 be redirected accordingly.
 */
@interface CDTFetchChanges : NSObject

#pragma mark Properties

/**
 The datastore whose changes should be fetched.
 
 Typically this is set with the initialiser.
 */
@property (nonatomic, strong) CDTDatastore *datastore;

//@property (nonatomic, assign) NSUInteger resultsLimit;
//@property (nonatomic, readonly) BOOL moreComing;


/**
 The sequence value identifying the starting point for reading changes.
 
 Each changes request returns a sequence value in the completion block. This sequence value
 can be used to receive changes that have occured since the previous request. Treat the
 sequence value as an opaque string; different implementations may provide differently
 formatted values. A given sequence value should only be used with the database that
 it was received from.
 
 Typically this is set with the initialiser.
 */
@property (nonatomic, copy) NSString *previousServerSequenceValue;

#pragma mark Callbacks

/**
 The block to execute for each changed document.
 
 The block returns no value and takes the following parameters:
 
 <dl>
 <dt>revision</dt>
 <dd>The winning revision for the document that changed.</dd>
 </dl>
 
 The operation object executes this block once for each document in the database that changed 
 since the previous fetch request. Each time the block is executed, it is executed 
 serially with respect to the other progress blocks of the operation. If no documents 
 changed, the block is not executed.
 
 If you intend to use this block to process results, set it before executing the 
 operation or submitting it to a queue. 
 */
@property (nonatomic, copy) void (^documentChangedBlock)(CDTDocumentRevision *revision);


/**
 The block to execute for each deleted document.
 
 The block returns no value and takes the following parameters:
 
 <dl>
 <dt>docId</dt>
 <dd>The document id for the deleted document.</dd>
 </dl>
 
 The operation object executes this block once for each document in the database that
 was deleted since the previous fetch request. Each time the block is executed, it 
 is executed serially with respect to the other progress blocks of the operation. 
 If no documents were deleted, the block is not executed.
 
 If you intend to use this block to process results, set it before executing the 
 operation or submitting it to a queue. 
 */
@property (nonatomic, copy) void (^documentWithIDWasDeletedBlock)(NSString *docId);

/**
 The block to execute when all changes have been reported. 
 
 The block returns no value and takes the following parameters:
 
 <dl>
 <dt>serverSequenceValue</dt>
 <dd>The new sequence value from the server. You can store this value locally and use it 
 during subsequent fetch operations to limit the results to records that changed since 
 this operation executed. A sequence value is only valid for the database it was
 originally retrieved from.</dd>
 
 <dt>clientSequenceValue</dt>
 <dd>The sequence value you specified when you initialized the operation object.</dd>
 
 <dt>fetchError</dt>
 <dd>An error object containing information about a problem, or nil if the changes are 
 retrieved successfully.</dd>
 </dl>
 
 The operation object executes this block only once, at the conclusion of the operation. It 
 is executed after all individual change blocks. 
 The block is executed serially with respect to the other progress blocks of the operation.
 
 If you intend to use this block to process results, set it before executing the operation or 
 submitting the operation object to a queue. 
 */
@property (nonatomic, copy) void (^fetchRecordChangesCompletionBlock)( 
NSString *serverSequenceValue, 
NSString *clientSequenceValue, 
NSError *fetchError);

#pragma mark Initialisers

/**
 Initializes and returns an object configured to fetch changes in the specified database.
 
 When initializing the fetch object, use the sequence value from a previous fetch request if 
 you have one. You can archive sequence values and write them to disk for later use if needed.
 
 After initializing the operation, associate at least one progress block with the operation 
 object (excluding the completion block) to process the results. 
 
 @param datastore The datastore containing the changes that should be fetched.
 @param previousServerChangeToken The sequence value from a previous fetch. This is the value
            passed to the completionHandler for this object. This value limits the changes
            retrieved to those occuring after this sequence value. Pass `nil` to receive
            all changes.
 
 @return An initialised fetch object.
 */
- (instancetype)initWithDatastore:(CDTDatastore *)datastore
        previousServerSequenceValue:(NSString *)previousServerSequenceValue;

#pragma mark Instance methods

/**
 Start the fetch request on a background queue.
 
 Be sure to assign callback blocks to handle results before calling this method.
 */
- (void)start;

@end
