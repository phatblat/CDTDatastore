//
//  CDTReadOnlyDatastore.h
//  
//
//  Created by tomblench on 10/02/2015.
//
//

#import "CDTDatastore.h"

@interface CDTReadOnlyDatastore : CDTDatastore

- (id)initWithDatabase:(TD_Database *)database
                   ids:(NSArray*)ids;

@end
