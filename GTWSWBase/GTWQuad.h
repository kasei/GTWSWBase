#import <Foundation/Foundation.h>
#import <Foundation/NSKeyValueCoding.h>
#import "GTWSWBase.h"
#import "GTWTriple.h"

@interface GTWQuad : NSObject<GTWQuad,GTWRewriteable, NSCopying>

@property id<GTWTerm> subject;
@property id<GTWTerm> predicate;
@property id<GTWTerm> object;
@property id<GTWTerm> graph;

- (GTWQuad*) initWithSubject: (id<GTWTerm>) subj predicate: (id<GTWTerm>) pred object: (id<GTWTerm>) obj graph: (id<GTWTerm>) graph;
+ (GTWQuad*) quadFromTriple: (id<GTWTriple>) t withGraph: (id<GTWTerm>) graph;

@end
