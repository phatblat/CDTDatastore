//
//  CDTReadOnlyDatastore.m
//  
//
//  Created by tomblench on 10/02/2015.
//
//

#import "CDTReadOnlyDatastore.h"

@implementation CDTReadOnlyDatastore

- (id)initWithDatabase:(TD_Database *)database
                   ids:(NSArray*)ids
{
    // TODO
    return nil;
}

- (CDTDocumentRevision *)createDocumentFromRevision:(CDTMutableDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error
{
    // TODO throw exception?
    return nil;
}

- (CDTDocumentRevision *)updateDocumentFromRevision:(CDTMutableDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error
{
    // TODO throw exception?
    return nil;
}

- (CDTDocumentRevision *)deleteDocumentFromRevision:(CDTDocumentRevision *)revision
                                              error:(NSError *__autoreleasing *)error
{
    // TODO throw exception?
    return nil;
}

- (NSArray *)deleteDocumentWithId:(NSString *)docId error:(NSError *__autoreleasing *)error
{
    // TODO throw exception?
    return nil;
}

- (BOOL)compactWithError:(NSError *__autoreleasing *)error
{
    // TODO throw exception?
    klujdfklgjdflgjdf
    return NO;
}





@end
