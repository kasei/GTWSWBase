#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWBlank : NSObject<GTWBlank, NSCopying>

@property (retain, readwrite) NSString* value;

- (GTWBlank*) initWithID: (NSString*) ident;
- (GTWBlank*) initWithValue: (NSString*) value;

@end
