#import "GTWQuad.h"

@implementation GTWQuad

- (GTWQuad*) copy {
    return [self copyWithZone:nil];
}

- (id)copyWithZone:(NSZone *)zone {
    id<GTWTerm,NSCopying> s   = [self.subject copyWithZone:zone];
    id<GTWTerm,NSCopying> p   = [self.predicate copyWithZone:zone];
    id<GTWTerm,NSCopying> o   = [self.object copyWithZone:zone];
    id<GTWTerm,NSCopying> g   = [self.graph copyWithZone:zone];
                                 return [[[self class] alloc] initWithSubject:s predicate:p object:o graph:g];
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [[[self class] alloc] initWithSubject:[self.subject copyReplacingValues:map] predicate:[self.predicate copyReplacingValues:map] object:[self.object copyReplacingValues:map] graph: [self.graph copyReplacingValues:map]];
}


+ (GTWQuad*) quadFromTriple: (id<GTWTriple>) t withGraph: (id<GTWTerm>) graph {
    GTWQuad* q  = [[self alloc] initWithSubject:t.subject predicate:t.predicate object:t.object graph:graph];
    return q;
}

- (GTWQuad*) initWithSubject: (id<GTWTerm>) subj predicate: (id<GTWTerm>) pred object: (id<GTWTerm>) obj graph:(id<GTWTerm>)graph {
    if (self = [self init]) {
        self.subject    = subj;
        self.predicate  = pred;
        self.object     = obj;
        self.graph      = graph;
    }
    return self;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ %@ %@ %@ .", self.subject, self.predicate, self.object, self.graph];
}

- (BOOL) isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(GTWQuad)]){
        id<GTWQuad> t = object;
        if (![self.subject isEqual:t.subject])
            return NO;
        if (![self.predicate isEqual:t.predicate])
            return NO;
        if (![self.object isEqual:t.object])
            return NO;
        if (![self.graph isEqual:t.graph])
            return NO;
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return [[self description] hash];
}

- (NSArray*) allValues {
    return @[ self.subject, self.predicate, self.object, self.graph ];
}

@end
