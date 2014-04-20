#import "GTWVariable.h"

@implementation GTWVariable

- (GTWVariable*) copy {
    return [[[self class] alloc] initWithValue: self.value];
}

- (id<GTWTerm>) copyWithCanonicalization {
    return [self copy];
}

- (GTWVariable*) initWithValue: (NSString*) name {
    if (self = [self init]) {
        self.value  = name;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] alloc] initWithValue:self.value];
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [self copy];
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

- (BOOL) isValueEqual:(id<GTWTerm>)object {
    return [self isEqual:object];
}

- (NSComparisonResult)compare:(id<GTWTerm>)term reverse:(BOOL)reverseFlag {
    NSComparisonResult r = [self compare:term];
    if (reverseFlag) {
        if (r == NSOrderedDescending) {
            r   = NSOrderedAscending;
        } else if (r == NSOrderedAscending) {
            r   = NSOrderedDescending;
        }
    }
    return r;
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
