#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWLiteral : NSObject<GTWLiteral, GTWRewriteable,NSCopying>

@property (retain, readwrite) NSString* value;
@property (retain, readwrite) NSString* language;
@property (retain, readwrite) NSString* datatype;

+ (BOOL) literal: (id<GTWLiteral>) l isComparableWith: (id<GTWLiteral>) term;
+ (NSSet*) supportedDatatypes;
+ (GTWLiteral*) trueLiteral;
+ (GTWLiteral*) falseLiteral;
+ (GTWLiteral*) integerLiteralWithValue: (NSInteger) value;
+ (GTWLiteral*) doubleLiteralWithValue: (double) value;
+ (NSString*) promotedTypeForNumericTypes: (NSString*) lhs and: (NSString*) rhs;

- (GTWLiteral*) initWithValue: (NSString*) string;
- (GTWLiteral*) initWithValue: (NSString*) string language: (NSString*) language;
- (GTWLiteral*) initWithValue: (NSString*) string datatype: (NSString*) datatype;
- (GTWLiteral*) initWithValue: (NSString*) string datatype: (NSString*) datatype canonicalize: (BOOL) canon;

- (BOOL) booleanValue;
- (NSInteger) integerValue;
- (double) doubleValue;
- (BOOL) isSimpleLiteral;
- (BOOL) isArgumentCompatibileWith: (id<GTWLiteral>) literal;

@end
