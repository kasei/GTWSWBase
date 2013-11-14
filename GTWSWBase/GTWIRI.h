#import "GTWSWBase.h"

@interface GTWIRI : NSObject<GTWIRI, GTWRewriteable, NSCopying>

@property (retain, readwrite) NSString* value;

- (GTWIRI*) initWithValue: (NSString*) value;
- (GTWIRI*) initWithValue: (NSString*) iri base: (GTWIRI*) base;
- (GTWIRI*) initWithValue: (NSString*) iri relativeToIRI: (GTWIRI*) base;

@end

