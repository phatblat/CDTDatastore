//
//  CDTPullerByDocId.h
//  
//
//  Created by Michael Rhodes on 14/01/2015.
//
//

#import <Foundation/Foundation.h>

@class CDTDatastore;

@interface CDTPullerByDocId : NSObject {
    BOOL _stopRunLoop;
}

/** Called when replication is complete */
@property (nonatomic,copy) void(^completionBlock)();

/**
 Initialise a CDTPullerByDocId.
 
 @param source Source database URL
 @param target Target local database
 @param docIdsToPull List of documents to replicate.
 */
-(instancetype)initWithSource:(NSURL*)source
                       target:(CDTDatastore*)target
                 docIdsToPull:(NSArray*)docIdsToPull;

/** Asynchronously get updates to the documents passed to the constructor */
-(BOOL)start;

@end
