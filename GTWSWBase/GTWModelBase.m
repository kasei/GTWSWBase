#import "GTWModelBase.h"
#import "GTWBlank.h"
#import "GTWQuad.h"
#import "GTWGraphIsomorphism.h"

@implementation GTWModelBase

- (NSArray*) objectsForSubject: (id<GTWTerm>) subject predicate: (id<GTWTerm>) predicate graph: (id<GTWTerm>) graph {
    NSMutableArray* objects = [NSMutableArray array];
    [self enumerateQuadsMatchingSubject:subject predicate:predicate object:nil graph:graph usingBlock:^(id<GTWQuad> q) {
        [objects addObject:q.object];
    } error:nil];
    return objects;
}

- (id<GTWTerm>) anyObjectForSubject: (id<GTWTerm>) subject predicate: (id<GTWTerm>) predicate graph: (id<GTWTerm>) graph {
    NSArray* array  = [self objectsForSubject:subject predicate:predicate graph:graph];
    if (array && [array count]) {
        return array[0];
    } else {
        return nil;
    }
}

- (NSEnumerator*) quadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g  error:(NSError **)error {
    NSMutableArray* quads   = [[NSMutableArray alloc] init];
    [self enumerateQuadsMatchingSubject:s predicate:p object:o graph:g usingBlock:^(id<GTWQuad> q) {
        [quads addObject:q];
    } error:error];
    return [quads objectEnumerator];
}

- (BOOL) isEqual:(id<GTWModel>)model {
    return [GTWGraphIsomorphism
            graphEnumerator:[self quadsMatchingSubject:nil predicate:nil object:nil graph:nil error:nil]
            isomorphicWith:[model quadsMatchingSubject:nil predicate:nil object:nil graph:nil error:nil]];
}

@end
