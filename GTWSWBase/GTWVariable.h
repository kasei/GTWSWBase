#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface GTWVariable : NSObject<GTWVariable, NSCopying>

@property (retain, readwrite) NSString* value;

- (GTWVariable*) initWithValue: (NSString*) value;
- (GTWVariable*) initWithName: (NSString*) name;

@end
