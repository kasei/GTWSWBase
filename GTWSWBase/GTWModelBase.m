#import "GTWModelBase.h"
#import "GTWBlank.h"
#import "GTWQuad.h"

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

- (BOOL) isEqual:(id<GTWModel>)model {
    NSMutableSet* thisStatementsWithBlanks  = [NSMutableSet set];
    NSMutableSet* thatStatementsWithBlanks  = [NSMutableSet set];
    {
        NSMutableSet* thisStatementsWithoutBlanks  = [NSMutableSet set];
        NSMutableSet* thatStatementsWithoutBlanks  = [NSMutableSet set];
        [self enumerateQuadsMatchingSubject:nil predicate:nil object:nil graph:nil usingBlock:^(id<GTWQuad> q) {
            if ([q.subject termType] != GTWTermBlank && [q.predicate termType] != GTWTermBlank && [q.object termType] != GTWTermBlank && [q.graph termType] != GTWTermBlank) {
                [thisStatementsWithoutBlanks addObject:q];
            } else {
                [thisStatementsWithBlanks addObject:q];
            }
        } error:nil];
        [model enumerateQuadsMatchingSubject:nil predicate:nil object:nil graph:nil usingBlock:^(id<GTWQuad> q) {
            if ([q.subject termType] != GTWTermBlank && [q.predicate termType] != GTWTermBlank && [q.object termType] != GTWTermBlank && [q.graph termType] != GTWTermBlank) {
                [thatStatementsWithoutBlanks addObject:q];
            } else {
                [thatStatementsWithBlanks addObject:q];
            }
        } error:nil];
        
//        NSLog(@"%@\n%@\n%@\n%@\n", thisStatementsWithoutBlanks, thisStatementsWithBlanks, thatStatementsWithoutBlanks, thatStatementsWithBlanks);
        
        if (![thisStatementsWithoutBlanks isEqual:thatStatementsWithoutBlanks]) {
            NSLog(@"models have different sets of statements without blanks");
            NSLog(@"got: %@\n\nexpected: %@\n", thisStatementsWithoutBlanks, thatStatementsWithoutBlanks);
            return NO;
        }
    }
    
    if ([thisStatementsWithBlanks count] == 0 && [thatStatementsWithBlanks count] == 0) {
        NSLog(@"no statements with blanks");
        NSLog(@"models are isomorphic");
        return YES;
    }
    
    NSDictionary* map   = [self findBijectionFrom: thisStatementsWithBlanks to: thatStatementsWithBlanks];
    if (map) {
        NSLog(@"models are isomorphic");
        return YES;
    } else {
        NSLog(@"no bijection found between blank node sets");
        return NO;
    }
}

- (NSDictionary*) findBijectionFrom: (NSSet*) aStatements to: (NSSet*) bStatements {
    NSMutableSet* thisBlanks    = [NSMutableSet set];
    NSMutableSet* thatBlanks    = [NSMutableSet set];
    for (id<GTWQuad> q in aStatements) {
        if ([q.subject termType] == GTWTermBlank)
            [thisBlanks addObject:q.subject];
        if ([q.predicate termType] == GTWTermBlank)
            [thisBlanks addObject:q.predicate];
        if ([q.object termType] == GTWTermBlank)
            [thisBlanks addObject:q.object];
        if ([q.graph termType] == GTWTermBlank)
            [thisBlanks addObject:q.graph];
    }
    for (id<GTWQuad> q in bStatements) {
        if ([q.subject termType] == GTWTermBlank)
            [thatBlanks addObject:q.subject];
        if ([q.predicate termType] == GTWTermBlank)
            [thatBlanks addObject:q.predicate];
        if ([q.object termType] == GTWTermBlank)
            [thatBlanks addObject:q.object];
        if ([q.graph termType] == GTWTermBlank)
            [thatBlanks addObject:q.graph];
    }
    
//    NSLog(@"blanks:\n%@\n%@", thisBlanks, thatBlanks);
    if ([thisBlanks count] != [thatBlanks count]) {
        NSLog(@"models have different number of blanks");
        return NO;
    }
    
    NSArray* aArray = [thisBlanks allObjects];
    NSArray* bArray = [thatBlanks allObjects];
    if ([aArray count] == 0) {
        return @{};
    }
    __block NSDictionary* indexMap;
    [self enumeratePermutationsOfIndexesWithCount:[aArray count] withBlock:^BOOL(int* map) {
        NSMutableDictionary* bijection  = [NSMutableDictionary dictionary];
        int i;
        NSUInteger count    = [aArray count];
        for (i = 0; i < count; i++) {
            [bijection setObject:bArray[i] forKey:aArray[map[i]]];
        }
//        NSLog(@"trying bijection: %@", bijection);
        NSMutableSet* mappedStatements    = [NSMutableSet setWithCapacity:[aStatements count]];
        for (id<GTWQuad> q in aStatements) {
            id<GTWTerm> s   = q.subject;
            id<GTWTerm> p   = q.predicate;
            id<GTWTerm> o   = q.object;
            id<GTWTerm> g   = q.graph;
            if ([s termType] == GTWTermBlank) {
//                NSLog(@"subject %@ is a blank. mapping it to %@", s, bijection[s]);
                s   = [bijection[s] copy];
            }
            if ([p termType] == GTWTermBlank)
                p   = [bijection[p] copy];
            if ([o termType] == GTWTermBlank)
                o   = [bijection[o] copy];
            if ([g termType] == GTWTermBlank)
                g   = [bijection[g] copy];
            GTWQuad* mapped = [[GTWQuad alloc] initWithSubject:s predicate:p object:o graph:g];
            [mappedStatements addObject:mapped];
        }
        if ([mappedStatements isEqual:bStatements]) {
            indexMap    = bijection;
            return YES;
        } else {
            return NO;
        }
    }];
    return indexMap;
}

BOOL constructPermutation (NSMutableIndexSet* set, int* map, int current, unsigned long max, BOOL(^block)(int*)) {
//    NSLog(@"constructPermutation: %p, %p, %d, %lu, %p", set, map, current, max, block);
    int i;
    for (i = 0; i <= max; i++) {
//        NSLog(@"--> trying permutation index %d", i);
        if (![set containsIndex:i]) {
//            NSLog(@"----> with value %d", i);
            NSMutableIndexSet* newSet   = [set mutableCopy];
            map[current]    = i;
            [newSet addIndex:i];
            if (current < max) {
                BOOL stop   = constructPermutation(newSet, map, current+1, max, block);
                if (stop)
                    return stop;
            } else {
//                NSLog(@"--> full permutation");
                return block(map);
            }
        }
    }
    return NO;
}

- (void) enumeratePermutationsOfIndexesWithCount: (unsigned long) count withBlock: (BOOL(^)(int*))block {
    if (count == 0) {
        NSLog(@"*** trying to enumerate permutations with zero items");
        return;
    }
    int max = ((int)count)-1;
    int* indexes    = calloc(sizeof(int), max);
    NSMutableIndexSet* set  = [NSMutableIndexSet indexSet];
    constructPermutation(set, indexes, 0, max, ^(int*a){
//        int i;
//        fprintf(stderr, "permutation: ");
//        for (i = 0; i <= max; i++) {
//            fprintf(stderr, "%d->%d ", i, a[i]);
//        }
//        fprintf(stderr, "\n");
        return block(a);
        
    });
    return;
}

@end
