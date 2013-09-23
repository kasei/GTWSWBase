#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWDataset : NSObject<GTWDataset>

typedef NS_ENUM(NSInteger, GTWDatasetAvailability) {
    GTWFullDataset,
    GTWRestrictedDataset
};

@property GTWDatasetAvailability availabilityType;
@property NSMutableArray* defaultGraphsStack;
@property NSArray* graphs;

- (GTWDataset*) initDatasetWithDefaultGraphs: (NSArray*) defaultGraphs;
- (GTWDataset*) initDatasetWithDefaultGraphs: (NSArray*) defaultGraphs restrictedToGraphs: (NSArray*) graphs;
- (NSArray*) defaultGraphs;
- (NSArray*) availableGraphsFromModel: (id<GTWModel>) model;

@end
