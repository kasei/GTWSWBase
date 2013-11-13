#import "GTWTriple.h"

@implementation GTWTriple

- (GTWTriple*) copy {
    return [self copyWithZone:nil];
}

- (id)copyWithZone:(NSZone *)zone {
    id<GTWTerm,NSCopying> s   = [self.subject copyWithZone:zone];
    id<GTWTerm,NSCopying> p   = [self.predicate copyWithZone:zone];
    id<GTWTerm,NSCopying> o   = [self.object copyWithZone:zone];
    return [[[self class] alloc] initWithSubject:s predicate:p object:o];
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [[[self class] alloc] initWithSubject:[self.subject copyReplacingValues:map] predicate:[self.predicate copyReplacingValues:map] object:[self.object copyReplacingValues:map]];
}

- (id<GTWStatement>) copyWithCanonicalization {
    id<GTWTerm,NSCopying> s   = [self.subject copyWithCanonicalization];
    id<GTWTerm,NSCopying> p   = [self.predicate copyWithCanonicalization];
    id<GTWTerm,NSCopying> o   = [self.object copyWithCanonicalization];
    return [[[self class] alloc] initWithSubject:s predicate:p object:o];
}

+ (GTWTriple*) tripleFromQuad: (id<GTWQuad>) q {
    return [[GTWTriple alloc] initWithSubject:q.subject predicate:q.predicate object:q.object];
}

- (GTWTriple*) initWithSubject: (id<GTWTerm>) subj predicate: (id<GTWTerm>) pred object: (id<GTWTerm>) obj {
    if (self = [self init]) {
        if (!subj || subj == (id<GTWTerm>)[NSNull null]) {
            NSLog(@"triple with nil subject");
            return nil;
        }
        self.subject    = subj;
        self.predicate  = pred;
        self.object     = obj;
    }
    return self;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ %@ %@ .", self.subject, self.predicate, self.object];
}

- (BOOL) isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(GTWTriple)]){
        id<GTWTriple> t = object;
        if (![self.subject isEqual:t.subject])
            return NO;
        if (![self.predicate isEqual:t.predicate])
            return NO;
        if (![self.object isEqual:t.object])
            return NO;
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return [[self description] hash];
}

- (NSArray*) allValues {
    return @[ self.subject, self.predicate, self.object ];
}

- (BOOL) isGround {
    for (id<GTWTerm> t in [self allValues]) {
        if (!(t.termType == GTWTermBlank || t.termType == GTWTermLiteral || t.termType == GTWTermIRI)) {
            return NO;
        }
    }
    return YES;
}

@end
