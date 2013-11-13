#import "GTWBlank.h"

@implementation GTWBlank

- (GTWBlank*) copy {
    return [[[self class] alloc] initWithValue: self.value];
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [self copy];
}

- (id<GTWTerm>) copyWithCanonicalization {
    return [self copy];
}

- (GTWBlank*) initWithValue: (NSString*) value {
    if (self = [self init]) {
        self.value  = value;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

- (GTWTermType) termType {
    return GTWTermBlank;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"_:%@", self.value];
}

- (BOOL) isEqual:(id)object {
//    NSLog(@"%@ <=> %@", self, object);
    if ([object conformsToProtocol:@protocol(GTWTerm)]){
        id<GTWTerm> term    = object;
        if (self.termType == term.termType) {
            if ([self.value isEqual:term.value]) {
//                NSLog(@"-> YES");
                return YES;
            }
        }
    }
//    NSLog(@"-> NO");
    return NO;
}

- (BOOL) isValueEqual:(id<GTWTerm>)object {
    return [self isEqual:object];
}

- (NSComparisonResult)compare:(id<GTWTerm>)term {
    if (!term)
        return NSOrderedDescending;
    if (self.termType != term.termType) {
        return NSOrderedAscending;
    } else {
        return [self.value compare:term.value];
    }
}

- (NSUInteger)hash {
    return [self.value hash];
}

- (BOOL) effectiveBooleanValueWithError: (NSError**) error {
    return NO;
}

@end
