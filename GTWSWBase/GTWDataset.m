#import "GTWDataset.h"
#import "GTWSWBase.h"

@implementation GTWDataset

+ (GTWDataset*) datasetFromDataset: (GTWDataset*) dataset withDefaultGraphs: (NSArray*) defaultGraphs {
    GTWDataset* ds  = [[self alloc] initDatasetWithDefaultGraphs: defaultGraphs];
    ds.availabilityType = dataset.availabilityType;
    ds.graphs           = dataset.graphs;
    return ds;
}

- (GTWDataset*) initDatasetWithDefaultGraphs: (NSArray*) defaultGraphs {
    if (self = [super init]) {
        self.availabilityType   = GTWFullDataset;
        self.graphs             = nil;
        self.defaultGraphsStack = [NSMutableArray array];
        [self.defaultGraphsStack addObject:defaultGraphs];
    }
    return self;
}

- (GTWDataset*) initDatasetWithDefaultGraphs: (NSArray*) defaultGraphs restrictedToGraphs: (NSArray*) graphs {
    if (self = [super init]) {
        self.availabilityType   = GTWRestrictedDataset;
        self.graphs             = graphs;
        self.defaultGraphsStack = [NSMutableArray array];
        [self.defaultGraphsStack addObject:defaultGraphs];
    }
    return self;
}

- (NSArray*) defaultGraphs {
    return [self.defaultGraphsStack lastObject];
}

- (void) pushDefaultGraphs: (NSArray*) graphs {
    [self.defaultGraphsStack addObject:graphs];
}

- (void) popDefaultGraphs {
    [self.defaultGraphsStack removeLastObject];
}

- (NSArray*) availableGraphsFromModel: (id<GTWModel>) model {
    if (self.availabilityType == GTWFullDataset) {
        NSMutableArray* graphs  = [NSMutableArray array];
        NSSet* defaultGraphs    = [NSSet setWithArray:[self.defaultGraphsStack lastObject]];
        [model enumerateGraphsUsingBlock:^(id<GTWTerm> g){
            if (![defaultGraphs containsObject:g]) {
                [graphs addObject:g];
            }
        } error:nil];
        return graphs;
    } else {
        return self.graphs;
    }
}

- (NSString*) description {
    NSMutableString* s  = [NSMutableString stringWithFormat:@"GTWDataset"];
    if (self.availabilityType == GTWRestrictedDataset) {
        [s appendFormat:@"(Restricted)"];
    }
    NSString* graphs    = [[self defaultGraphs] componentsJoinedByString:@", "];
    [s appendFormat:@"[%@]", graphs];
    return [s copy];
}

@end
