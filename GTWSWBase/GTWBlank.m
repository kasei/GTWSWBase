#import "GTWBlank.h"

@implementation GTWBlank

- (GTWBlank*) copy {
    return [[[self class] alloc] initWithValue: self.value];
}

- (GTWBlank*) initWithValue: (NSString*) value {
    return [self initWithID:value];
}

- (GTWBlank*) initWithID: (NSString*) ident {
    if (self = [self init]) {
        self.value  = ident;
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

@end
