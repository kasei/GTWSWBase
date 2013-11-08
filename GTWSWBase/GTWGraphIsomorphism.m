//
//  GTWGraphIsomorphism.m
//  GTWSWBase
//
//  Created by Gregory Williams on 9/23/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import "GTWGraphIsomorphism.h"
#import "GTWSWBase.h"
#import "GTWQuad.h"
#import "GTWTriple.h"

@implementation GTWGraphIsomorphism

+ (BOOL) graphEnumerator: (NSEnumerator*) a isomorphicWith: (NSEnumerator*) b reason: (NSError**) error {
    NSMutableSet* thisStatementsWithBlanks  = [NSMutableSet set];
    NSMutableSet* thatStatementsWithBlanks  = [NSMutableSet set];
    {
        NSMutableSet* thisStatementsWithoutBlanks  = [NSMutableSet set];
        NSMutableSet* thatStatementsWithoutBlanks  = [NSMutableSet set];
        for (id<GTWQuad> q in a) {
            NSArray* terms  = [q allValues];
            BOOL hasBlanks  = NO;
            for (id<GTWTerm> t in terms) {
                if ([t termType] == GTWTermBlank) {
                    hasBlanks   = YES;
                }
            }
            
            if (hasBlanks) {
                [thisStatementsWithBlanks addObject:q];
            } else {
                [thisStatementsWithoutBlanks addObject:q];
            }
        }
        for (id<GTWQuad> q in b) {
            NSArray* terms  = [q allValues];
            BOOL hasBlanks  = NO;
            for (id<GTWTerm> t in terms) {
                if ([t termType] == GTWTermBlank) {
                    hasBlanks   = YES;
                }
            }
            
            if (hasBlanks) {
                [thatStatementsWithBlanks addObject:q];
            } else {
                [thatStatementsWithoutBlanks addObject:q];
            }
        }
        
        //        NSLog(@"%@\n%@\n%@\n%@\n", thisStatementsWithoutBlanks, thisStatementsWithBlanks, thatStatementsWithoutBlanks, thatStatementsWithBlanks);
        
        if (![thisStatementsWithoutBlanks isEqual:thatStatementsWithoutBlanks]) {
            NSString* string    = [NSString stringWithFormat:@"models have different sets of statements without blanks: %@\n%@", thisStatementsWithoutBlanks, thatStatementsWithoutBlanks];
            if (error) {
                *error  = [NSError errorWithDomain:@"us.kasei.swbase.graph-isomorphism" code:1 userInfo:@{@"description": string}];
            }
            return NO;
        }
    }
    
    if ([thisStatementsWithBlanks count] == 0 && [thatStatementsWithBlanks count] == 0) {
//        NSLog(@"no statements with blanks");
//        NSLog(@"models are isomorphic");
        return YES;
    }
    
    NSDictionary* map   = [self findBijectionFrom: thisStatementsWithBlanks to: thatStatementsWithBlanks];
    if (map) {
//        NSLog(@"models are isomorphic; bijection: %@", map);
        return YES;
    } else {
        NSString* string    = [NSString stringWithFormat:@"no bijection found between blank node sets"];
        if (error) {
            *error  = [NSError errorWithDomain:@"us.kasei.swbase.graph-isomorphism" code:1 userInfo:@{@"description": string}];
        }
        return NO;
    }
    return NO;
}

+ (NSDictionary*) findBijectionFrom: (NSSet*) aStatements to: (NSSet*) bStatements {
    NSMutableSet* thisBlanks    = [NSMutableSet set];
    NSMutableSet* thatBlanks    = [NSMutableSet set];
    for (id q in aStatements) {
        for (id t in [q allValues]) {
            if ([t termType] == GTWTermBlank)
                [thisBlanks addObject:t];
        }
    }
    for (id q in bStatements) {
        for (id t in [q allValues]) {
            if ([t termType] == GTWTermBlank)
                [thatBlanks addObject:t];
        }
    }
    
    //    NSLog(@"blanks:\n%@\n%@", thisBlanks, thatBlanks);
    if ([thisBlanks count] != [thatBlanks count]) {
//        NSLog(@"models have different number of blanks");
        return NO;
    }
    
    NSArray* aArray = [thisBlanks allObjects];
    NSArray* bArray = [thatBlanks allObjects];
    if ([aArray count] == 0) {
//        NSLog(@"trivial bijection found in graph with no blank nodes");
        return @{};
    }
    __block NSDictionary* indexMap;
    [self enumeratePermutationsOfIndexesWithCount:[aArray count] withBlock:^BOOL(int* map) {
        @autoreleasepool {
            NSMutableDictionary* bijection  = [NSMutableDictionary dictionary];
            int i;
            NSUInteger count    = [aArray count];
            for (i = 0; i < count; i++) {
                [bijection setObject:bArray[i] forKey:aArray[map[i]]];
            }
            //        NSLog(@"trying bijection: %@", bijection);
            NSMutableSet* mappedStatements    = [NSMutableSet setWithCapacity:[aStatements count]];
            for (id q in aStatements) {
                id mapped   = [self mapObject: q withBijection:bijection];
                [mappedStatements addObject:mapped];
            }
            if ([mappedStatements isEqual:bStatements]) {
                indexMap    = bijection;
                return YES;
            } else {
                return NO;
            }
        }
    }];
    
    return indexMap;
}

+ (id) mapObject: (id) obj withBijection: (NSDictionary*) bijection {
    int i;
    if ([[obj class] conformsToProtocol:@protocol(GTWQuad)]) {
        NSMutableArray* terms  = [[obj allValues] mutableCopy];
        for (i = 0; i < [terms count]; i++) {
            if ([terms[i] termType] == GTWTermBlank)
                terms[i]   = [bijection[terms[i]] copy];
        }
        GTWQuad* mapped = [[GTWQuad alloc] initWithSubject:terms[0] predicate:terms[1] object:terms[2] graph:terms[3]];
        return mapped;
    } else if ([[obj class] conformsToProtocol:@protocol(GTWTriple)]) {
        NSMutableArray* terms  = [[obj allValues] mutableCopy];
        for (i = 0; i < [terms count]; i++) {
            if ([terms[i] termType] == GTWTermBlank)
                terms[i]   = [bijection[terms[i]] copy];
        }
        GTWTriple* mapped = [[GTWTriple alloc] initWithSubject:terms[0] predicate:terms[1] object:terms[2]];
        return mapped;
    } else {
        NSMutableDictionary* mapped = [NSMutableDictionary dictionary];
        for (id k in obj) {
            id<GTWTerm> term    = obj[k];
            if ([term termType] == GTWTermBlank) {
                mapped[k]   = [bijection[term] copy];
            } else {
                mapped[k]   = obj[k];
            }
        }
        return mapped;
    }
}

BOOL constructPermutation (NSMutableIndexSet* set, int* map, int current, unsigned long max, BOOL(^block)(int*)) {
    //    NSLog(@"constructPermutation: %p, %p, %d, %lu, %p", set, map, current, max, block);
    int i;
    for (i = 0; i <= max; i++) {
        //        NSLog(@"--> trying permutation index %d", i);
        if (![set containsIndex:i]) {
            //            NSLog(@"----> with value %d", i);
            @autoreleasepool {
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
    }
    return NO;
}

+ (void) enumeratePermutationsOfIndexesWithCount: (unsigned long) count withBlock: (BOOL(^)(int*))block {
    if (count == 0) {
        NSLog(@"*** trying to enumerate permutations with zero items");
        return;
    }
//    NSLog(@"finding bijection over %lu blank nodes", count);
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
