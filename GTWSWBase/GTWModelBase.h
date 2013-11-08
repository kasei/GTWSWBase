#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWModelBase : NSObject<GTWModel>

- (NSArray*) subjectsForPredicate: (id<GTWTerm>) predicate object: (id<GTWTerm>) object graph: (id<GTWTerm>) graph;
- (NSArray*) objectsForSubject: (id<GTWTerm>) subject predicate: (id<GTWTerm>) predicate graph: (id<GTWTerm>) graph;
- (id<GTWTerm>) anyObjectForSubject: (id<GTWTerm>) subject predicate: (id<GTWTerm>) predicate graph: (id<GTWTerm>) graph;
- (id<GTWTerm>) anySubjectForPredicate: (id<GTWTerm>) predicate object: (id<GTWTerm>) object graph: (id<GTWTerm>) graph;
- (BOOL) isEqual:(id<GTWModel>)model;

@end
