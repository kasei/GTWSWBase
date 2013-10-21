#import "GTWVariable.h"

@implementation GTWVariable

- (GTWVariable*) copy {
    return [[[self class] alloc] initWithValue: self.value];
}

- (GTWVariable*) initWithValue: (NSString*) value {
    return [self initWithName:value];
}

- (GTWVariable*) initWithName: (NSString*) name {
    if (self = [self init]) {
        self.value  = name;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] alloc] initWithName:self.value];
}

- (GTWTermType) termType {
    return GTWTermVariable;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"?%@", self.value];
}

- (BOOL) isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(GTWTerm)]){
        id<GTWTerm> term    = object;
        if (self.termType == term.termType) {
            if ([self.value isEqual:term.value]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSComparisonResult)compare:(id<GTWTerm>)term {
    if (!term)
        return NSOrderedDescending;
    if (self.termType != term.termType) {
        NSLog(@"not the same type: %@ %@", self, term);
        return NSOrderedAscending;
    } else {
        NSLog(@"comparing values: %@ %@", self, term);
        return [self.value compare:term.value];
    }
}

- (NSUInteger)hash {
    return [self.value hash];
}

@end
