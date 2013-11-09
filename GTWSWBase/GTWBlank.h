#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWBlank : NSObject<GTWBlank, GTWRewriteable, NSCopying>

@property (retain, readwrite) NSString* value;

- (GTWBlank*) initWithValue: (NSString*) value;

@end
