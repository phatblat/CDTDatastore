//
//  CDTMutableDocumentRevision.h
//
//
//  Created by Rhys Short on 22/07/2014.
//
//

#import "CDTDocumentRevision.h"

@interface CDTMutableDocumentRevision : CDTDocumentRevision

@property (nonatomic, strong, readwrite, nullable) NSString *sourceRevId;
@property (nonatomic, strong, readwrite, nonnull) NSString *docId;
@property (nonatomic,strong, readwrite, nullable) NSString *revId;

/**
 *   Creates an empty CDTMutableDocumentRevision
 **/
+ ( nullable CDTMutableDocumentRevision *)revision;

/**
 * Initializes a CDTMutableDocumentRevision revision
 *
 * @param documentId The id of the document
 * @param body The body of the document
 *
 **/
- (nullable instancetype)initWithDocumentId:(nonnull NSString *)documentId body:(nonnull NSMutableDictionary *)body;

/**
 * Initializes a CDTMutableDocumentRevision
 * 
 * @param sourceRevId the parent revision id
 **/
- (nullable instancetype)initWithSourceRevisionId:(nonnull NSString *)sourceRevId;

/**
 Initializes a CDTMutableDocumentRevision
 
 @param documentId the id of the document
 @param body the body of the document
 @param attachments the document's attachments
 @param sourceRevId the parent revision id
 **/
- (nullable instancetype)initWithDocumentId:(nullable NSString*) documentId
                                       body:(nullable NSMutableDictionary *)body
                                attachments: (nullable NSMutableDictionary *)attachments
                           sourceRevisionId:(nullable NSString*)sourceRevId NS_DESIGNATED_INITIALIZER;

- (void)setBody:(nonnull NSDictionary *)body;

- (nonnull NSMutableDictionary *)body;

- (nonnull NSMutableDictionary *)attachments;

- (void)setAttachments:(nonnull NSDictionary *)attachments;

@end
