//
//  NSObject+GTWTerm.m
//  GTWSWBase
//
//  Created by Gregory Williams on 11/14/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import "NSObject+GTWTerm.h"
#import "GTWSWBase.h"

static NSString* XSD_DATE_PATTERN   = @"(-?)(\\d\\d\\d\\d)-(\\d\\d)-(\\d\\d)((([+]|-)\\d\\d:\\d\\d)|Z)?";
static NSString* INTEGER_PATTERN    = @"http://www.w3.org/2001/XMLSchema#(byte|int|integer|long|short|nonPositiveInteger|nonNegativeInteger|unsignedLong|unsignedInt|unsignedShort|unsignedByte|positiveInteger|negativeInteger)";

@implementation NSObject (GTWTerm)

- (BOOL) effectiveBooleanValueWithError: (NSError**) error {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (term.datatype && [term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#boolean"]) {
            BOOL ebv    = [term booleanValue];
            return ebv;
        } else if ((term.datatype && [term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#string"]) || (term.datatype && [term.datatype isEqualToString:@"http://www.w3.org/1999/02/22-rdf-syntax-ns#langString"]) || [term isSimpleLiteral]) {
            if ([term.value length] == 0) {
                return NO;
            } else {
                return YES;
            }
        } else if ([term isNumericLiteral]) {
            NSInteger ivalue    = [term integerValue];
            if (ivalue != 0) {
                return YES;
            } else {
                double value    = [term doubleValue];
                if (value == 0.0L) {
                    return NO;
                } else {
                    return YES;
                }
            }
            //    } else {
            //        NSLog(@"EBV of unexpected value: %@", term);
        }
        
        if (error) {
            *error  =  [NSError errorWithDomain:@"us.kasei.swbase.ebv" code:1 userInfo:@{@"description": @"EBV TypeError"}];
        }
    }
    return NO;
}

- (BOOL) isValidLexicalInteger {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (![term isIntegerLiteral])
            return NO;
        NSRange range   = [term.value rangeOfString:@"([+]|-)?\\d+" options:NSRegularExpressionSearch];
        if (range.location == 0 && range.length == [term.value length]) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

- (BOOL) isValidLexicalDouble {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (![term isDoubleLiteral])
            return NO;
        // TODO: Check lexical form
        if ([term.datatype isEqual:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
            NSRange range   = [term.value rangeOfString:@"([+]|-)?\\d+([.]\\d+)?" options:NSRegularExpressionSearch];
            if (range.location == 0 && range.length == [term.value length])
                return YES;
        } else {
            // xsd:float or xsd:double
            // TODO: We don't handle Inf or NaN here because we're using this function to know if we can use the double values in comparisons.
            NSRange range   = [term.value rangeOfString:@"([+]|-)?\\d+([.]\\d+([eE]([+]|-)?\\d+)?)?" options:NSRegularExpressionSearch];
            if (range.location == 0 && range.length == [term.value length])
                return YES;
        }
    }
    return NO;
}

- (BOOL) isValidXSDDate {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (!term.datatype)
            return NO;
        if (![term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#date"])
            return NO;
        NSRange range       = [term.value rangeOfString:XSD_DATE_PATTERN options:NSRegularExpressionSearch];
        if (range.location == 0 && range.length == [term.value length])
            return YES;
    }
    return NO;
}

- (NSDictionary*) xsdDateComponents {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        NSRegularExpression* re = [NSRegularExpression regularExpressionWithPattern:XSD_DATE_PATTERN options:0 error:nil];
        NSTextCheckingResult* r = [re firstMatchInString:term.value options:0 range:NSMakeRange(0, [term.value length])];
        NSRange signrange       = [r rangeAtIndex: 1];
        NSRange yearrange       = [r rangeAtIndex: 2];
        NSRange monthrange      = [r rangeAtIndex: 3];
        NSRange dayrange        = [r rangeAtIndex: 4];
        NSRange tzrange         = [r rangeAtIndex: 5];
        
        NSString* tz    = @"";
        if (tzrange.location != NSNotFound) {
            tz  = [term.value substringWithRange:tzrange];
            if ([tz isEqual: @"Z"]) {
                tz  = @"+00:00";
            } else if ([tz isEqual: @"-00:00"]) {
                tz  = @"+00:00";
            } else if ([tz isEqual: @"00:00"]) {
                tz  = @"+00:00";
            }
        }
        return @{
                 @"sign": [term.value substringWithRange:signrange],
                 @"year": [term.value substringWithRange:yearrange],
                 @"month": [term.value substringWithRange:monthrange],
                 @"day": [term.value substringWithRange:dayrange],
                 @"tz": tz,
                 };
    }
    return nil;
}

- (BOOL) isIntegerLiteral {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (!term.datatype)
            return NO;
        if ([term.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0)
            return YES;
    }
    return NO;
}

- (BOOL) isDoubleLiteral {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (!term.datatype)
            return NO;
        if ([term.datatype rangeOfString:@"http://www.w3.org/2001/XMLSchema#(decimal|double|float)" options:NSRegularExpressionSearch].location == 0)
            return YES;
    }
    return NO;
}

- (BOOL) isNumericLiteral {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        //    NSLog(@"isNumeric? %@", term.datatype);
        if (!term.datatype)
            return NO;
        if ([term.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
            return YES;
        } else if ([term.datatype rangeOfString:@"http://www.w3.org/2001/XMLSchema#(decimal|double|float)" options:NSRegularExpressionSearch].location == 0) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger) integerValue {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (!term.datatype)
            return 0;
        if ([term.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
            long long value = atoll([term.value UTF8String]);
            return (NSInteger) value;
        } else if ([term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
            return (NSInteger) [term doubleValue];
        } else if ([term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#double"]) {
            return (NSInteger) [term doubleValue];
        } else if ([term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
            return (NSInteger) [term doubleValue];
        }
    }
    return 0;
}

- (double) doubleValue {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (!term.datatype)
            return 0.0;
        if ([term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#double"] || [term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
            NSDecimalNumber *decNumber = [NSDecimalNumber decimalNumberWithString:term.value];
            return [decNumber doubleValue];
        } else if ([term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
            double v;
            sscanf([term.value UTF8String], "%lE", &v);
            return v;
        } else if ([term.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
            float v;
            sscanf([term.value UTF8String], "%f", &v);
            return (double) v;
        } else if ([term.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
            return (double) [term integerValue];
        }
    }
    return 0.0;
}

- (BOOL) isSimpleLiteral {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        if (term.datatype && ![term.datatype isEqual: @"http://www.w3.org/2001/XMLSchema#string"]) {
            return NO;
        }
        if (term.language) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL) isArgumentCompatibileWith: (id<GTWLiteral>) literal {
    if ([self conformsToProtocol:@protocol(GTWLiteral)]) {
        id<GTWLiteral> term = (id<GTWLiteral>)self;
        //Compatibility of two arguments is defined as:
        //
        //The arguments are simple literals or literals typed as xsd:string
        if ([term isSimpleLiteral] && [literal isSimpleLiteral]) {
            return YES;
        }
        
        //The arguments are plain literals with identical language tags
        if (term.language && literal.language && [term.language isEqual: literal.language]) {
            return YES;
        }
        
        //The first argument is a plain literal with language tag and the second argument is a simple literal or literal typed as xsd:string
        if (term.language && [literal isSimpleLiteral]) {
            return YES;
        }
    }
    return NO;
}

@end
