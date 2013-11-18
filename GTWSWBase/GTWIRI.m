#import "GTWIRI.h"
#import "IRI.h"

@implementation GTWIRI

- (GTWIRI*) copy {
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

- (GTWIRI*) initWithValue: (NSString*) iri {
    if (self = [self init]) {
        self.value  = iri;
    }
    return self;
}

- (GTWIRI*) initWithValue: (NSString*) iri base: (GTWIRI*) base {
    if (self = [self init]) {
        NSString* baseuri   = base.value;
        if (!baseuri) {
            NSLog(@"Undefined base URI passed to GTWIRI initWithIRI:base:");
            return nil;
        }
        
        IRI* bi = base ? [[IRI alloc] initWithValue:base.value relativeToIRI:nil] : nil;
        IRI* i  = [[IRI alloc] initWithValue:iri relativeToIRI:bi];
        self.value  = [i absoluteString];
        
//        NSURL* baseurl  = [[NSURL alloc] initWithString:baseuri];
//        NSURL* url  = [[NSURL alloc] initWithString:iri relativeToURL:baseurl];
//        self.value  = [url absoluteString];
        if (!self.value) {
            NSLog(@"failed to create IRI: <%@> with base %@", iri, base);
            return nil;
        }
    }
    return self;
}

- (GTWIRI*) initWithValue: (NSString*) iri relativeToIRI: (GTWIRI*) base {
    return [self initWithValue:iri relativeToIRI:base];
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
            if ([self.value isEqualToString:term.value]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL) isValueEqual:(id<GTWTerm>)object {
    return [self isEqual:object];
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
