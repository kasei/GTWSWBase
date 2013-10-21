#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWLiteral : NSObject<GTWLiteral>

@property (retain, readwrite) NSString* value;
@property (retain, readwrite) NSString* language;
@property (retain, readwrite) NSString* datatype;

+ (GTWLiteral*) trueLiteral;
+ (GTWLiteral*) falseLiteral;
+ (GTWLiteral*) integerLiteralWithValue: (NSInteger) value;
+ (GTWLiteral*) doubleLiteralWithValue: (double) value;


- (GTWLiteral*) initWithValue: (NSString*) value;
- (GTWLiteral*) initWithString: (NSString*) string;
- (GTWLiteral*) initWithString: (NSString*) string language: (NSString*) language;
- (GTWLiteral*) initWithString: (NSString*) string datatype: (NSString*) datatype;

- (BOOL) booleanValue;
- (NSInteger) integerValue;
- (double) doubleValue;

@end
