#import "GTWIRI.h"

@implementation GTWIRI

- (GTWIRI*) copy {
    return [[[self class] alloc] initWithValue: self.value];
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [self copy];
}

- (GTWIRI*) initWithValue: (NSString*) value {
    return [self initWithIRI:value];
}

- (GTWIRI*) initWithIRI: (NSString*) iri {
    if (self = [self init]) {
        self.value  = iri;
    }
    return self;
}

- (GTWIRI*) initWithIRI: (NSString*) iri base: (GTWIRI*) base {
    if (self = [self init]) {
        NSString* baseuri   = base.value;
        if (!baseuri) {
            NSLog(@"Undefined base URI passed to GTWIRI initWithIRI:base:");
            return nil;
        }
        NSURL* baseurl  = [[NSURL alloc] initWithString:baseuri];
        NSURL* url  = [[NSURL alloc] initWithString:iri relativeToURL:baseurl];
        self.value  = [url absoluteString];
        if (!self.value) {
            NSLog(@"failed to create IRI: <%@> with base %@", iri, base);
            return nil;
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

- (GTWTermType) termType {
    return GTWTermIRI;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@>", self.value];
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
        if (term.termType == GTWTermBlank)
            return NSOrderedDescending;
        return NSOrderedAscending;
    } else {
        return [self.value compare:term.value];
    }
}

- (NSUInteger)hash {
    return [self.value hash];
}

@end
