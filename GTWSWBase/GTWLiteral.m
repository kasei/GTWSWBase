#import "GTWLiteral.h"

static NSString* INTEGER_PATTERN    = @"http://www.w3.org/2001/XMLSchema#(byte|int|integer|long|short|nonPositiveInteger|nonNegativeInteger|unsignedLong|unsignedInt|unsignedShort|unsignedByte|positiveInteger|negativeInteger)";
static NSString* XSD_DATE_PATTERN   = @"(-?)(\\d\\d\\d\\d)-(\\d\\d)-(\\d\\d)((([+]|-)\\d\\d:\\d\\d)|Z)?";

@implementation GTWLiteral

+ (NSSet*) supportedDatatypes {
    static NSSet *_datatypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _datatypes = [NSSet setWithObjects:@"http://www.w3.org/2001/XMLSchema#string", @"http://www.w3.org/2001/XMLSchema#date", @"http://www.w3.org/2001/XMLSchema#dateTime", @"http://www.w3.org/2001/XMLSchema#byte", @"http://www.w3.org/2001/XMLSchema#int", @"http://www.w3.org/2001/XMLSchema#integer", @"http://www.w3.org/2001/XMLSchema#long", @"http://www.w3.org/2001/XMLSchema#short", @"http://www.w3.org/2001/XMLSchema#nonPositiveInteger", @"http://www.w3.org/2001/XMLSchema#nonNegativeInteger", @"http://www.w3.org/2001/XMLSchema#unsignedLong", @"http://www.w3.org/2001/XMLSchema#unsignedInt", @"http://www.w3.org/2001/XMLSchema#unsignedShort", @"http://www.w3.org/2001/XMLSchema#unsignedByte", @"http://www.w3.org/2001/XMLSchema#positiveInteger", @"http://www.w3.org/2001/XMLSchema#negativeInteger", @"http://www.w3.org/2001/XMLSchema#decimal", @"http://www.w3.org/2001/XMLSchema#float", @"http://www.w3.org/2001/XMLSchema#double", nil];
    });
    
    return _datatypes;
}

+ (GTWLiteral*) trueLiteral {
    static GTWLiteral* _literal;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _literal    = [[GTWLiteral alloc] initWithValue:@"true" datatype:@"http://www.w3.org/2001/XMLSchema#boolean"];
    });
    return _literal;
}

+ (GTWLiteral*) falseLiteral {
    static GTWLiteral* _literal;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _literal    = [[GTWLiteral alloc] initWithValue:@"false" datatype:@"http://www.w3.org/2001/XMLSchema#boolean"];
    });
    return _literal;
}

- (GTWLiteral*) copy {
    if (self.language) {
        return [[[self class] alloc] initWithValue: self.value language:self.language];
    } else if (self.datatype) {
        return [[[self class] alloc] initWithValue: self.value datatype:self.datatype];
    } else {
        return [[[self class] alloc] initWithValue: self.value];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

- (id<GTWTerm>) copyWithCanonicalization {
    if (self.datatype) {
        return [[[self class] alloc] initWithValue: self.value datatype:self.datatype canonicalize: YES];
    } else {
        return [self copy];
    }
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [self copy];
}

+ (GTWLiteral*) integerLiteralWithValue: (NSInteger) value {
    return [[GTWLiteral alloc] initWithValue:[NSString stringWithFormat:@"%ld", value] datatype:@"http://www.w3.org/2001/XMLSchema#integer"];
}

+ (GTWLiteral*) doubleLiteralWithValue: (double) value {
    return [[GTWLiteral alloc] initWithValue:[NSString stringWithFormat:@"%lE", value] datatype:@"http://www.w3.org/2001/XMLSchema#double"];
}

- (GTWLiteral*) initWithValue: (NSString*) string {
    if (self = [self init]) {
        self.value  = string;
    }
    return self;
}

- (GTWLiteral*) initWithValue: (NSString*) string language: (NSString*) language {
    if (self = [self init]) {
        self.value      = string;
        self.language   = [language lowercaseString];
        self.datatype   = @"http://www.w3.org/1999/02/22-rdf-syntax-ns#langString";
    }
    return self;
}

- (GTWLiteral*) initWithValue: (NSString*) string datatype: (NSString*) datatype {
    return [self initWithValue:string datatype:datatype canonicalize:NO];
}

- (GTWLiteral*) initWithValue: (NSString*) string datatype: (NSString*) datatype canonicalize: (BOOL) canon {
    if (self = [self init]) {
        NSSet* types    = [GTWLiteral supportedDatatypes];
        self.value      = string;
        self.datatype   = datatype;
        if (canon) {
            if ([types containsObject:datatype]) {
                if ([self isInteger]) {
                    self.value  = [NSString stringWithFormat:@"%ld", [self integerValue]];
                } else if ([self isDouble]) {
                    if ([datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
                        double dv   = [self doubleValue];
                        self.value  = [NSString stringWithFormat:@"%lg", dv];
                    } else {
                        self.value  = [NSString stringWithFormat:@"%lE", [self doubleValue]];
                    }
                }
            }
        }
    }
    return self;
}

- (GTWTermType) termType {
    return GTWTermLiteral;
}

- (NSString*) description {
    NSString* serialized    = [[[[self.value stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    if (self.language) {
        return [NSString stringWithFormat:@"\"%@\"@%@", serialized, self.language];
    } else if (self.datatype) {
        return [NSString stringWithFormat:@"\"%@\"^^<%@>", serialized, self.datatype];
    } else {
        return [NSString stringWithFormat:@"\"%@\"", serialized];
    }
}

- (BOOL) isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(GTWTerm)]){
        id<GTWTerm> term    = object;
        if (self.termType == term.termType) {
            if ([self.value isEqualToString:term.value]) {
                if ([self.language isEqualToString:term.language]) {
                    return YES;
                } else if (self.language || term.language) {
                    return NO;
                }
                if ([self.datatype isEqualToString:term.datatype]) {
                    return YES;
                } else if (self.datatype || term.datatype) {
                    return NO;
                }
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL) isValueEqual:(id<GTWTerm>)object {
    if ([self isEqual:object]) {
        return YES;
    }

    if ([object conformsToProtocol:@protocol(GTWTerm)]){
        id<GTWTerm> term    = object;
        if (self.termType == term.termType) {
            id<GTWLiteral> literal  = (id<GTWLiteral>) term;
            if ([self isNumeric] && [literal isNumeric]) {
                if ([self isDouble] || [literal isDouble]) {
                    if ([self doubleValue] == [literal doubleValue]) {
                        return YES;
                    } else {
                        return NO;
                    }
                } else {
                    if ([self integerValue] == [literal integerValue]) {
                        return YES;
                    } else {
                        return NO;
                    }
                }
            } else if ([self isValidXSDDate] && [(GTWLiteral*)literal isValidXSDDate]) {
                NSComparisonResult cmp  = [self compare:object];
                if (cmp == NSOrderedSame) {
                    return YES;
                } else {
                    return NO;
                }
            }
        }
    }
    return NO;
}

+ (BOOL) literal: (id<GTWLiteral>) l isComparableWith: (id<GTWLiteral>) term {
    if (!term)
        return NO;
    if (l.termType != term.termType) {
        return YES;
    } else {
        id<GTWLiteral> literal  = (id<GTWLiteral>) term;
        if (!l.datatype && !term.datatype) {
            return YES;
        } else if ([l isNumeric] && [literal isNumeric]) {
            if ([l isInteger]) {
                if (![(GTWLiteral*)l isValidLexicalInteger]) {
                    return NO;
                }
            }
            if ([l isDouble]) {
                if (![(GTWLiteral*)l isValidLexicalDouble]) {
                    return NO;
                }
            }
            return YES;
        } else if (l.datatype && term.datatype) {
            if ([l.datatype isEqual: term.datatype]) {
                if ([l.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#date"]) {
                    return YES;
                } else if ([l.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#dateTime"]) {
                    return YES;
                } else {
                    if ([l.value isEqualToString:term.value]) {
                        // Unknown datatype, but identical lexical forms, so the terms are equal
                        return YES;
                    }
                    return NO;
                }
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    }
}

- (NSComparisonResult)compare:(id<GTWTerm>)term {
    if (!term)
        return NSOrderedDescending;
    if (self.termType != term.termType) {
        if (term.termType == GTWTermBlank || term.termType == GTWTermIRI)
            return NSOrderedDescending;
        return NSOrderedAscending;
    } else {
        id<GTWLiteral> literal  = (id<GTWLiteral>) term;
        NSComparisonResult cmp;
        if (!self.datatype && !term.datatype) {
            return [self.value compare:term.value];
        } else if ([self isNumeric] && [literal isNumeric]) {
            double sv   = [self doubleValue];
            double lv   = [literal doubleValue];
            if (sv < lv) {
                return NSOrderedAscending;
            } else if (sv > lv) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        } else if (self.datatype && term.datatype) {
            cmp = [self.datatype compare:term.datatype];
            if (cmp != NSOrderedSame)
                return cmp;
            
            if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#date"]) {
                NSLog(@"comparing typed literal: %@ %@", self, term);
                if ([self isValidXSDDate] && [(GTWLiteral*)literal isValidXSDDate]) {
                    NSDictionary* thisDate = [self xsdDateComponents];
                    NSDictionary* thatDate  = [(GTWLiteral*)literal xsdDateComponents];
                    BOOL thisTZ             = ([thisDate[@"tz"] length] ? YES : NO);
                    BOOL thatTZ             = ([thatDate[@"tz"] length] ? YES : NO);
                    if (thisTZ && thatTZ) {
                        return [self.value compare:term.value];
                    } else {
                        // TODO: need to fuzzy compare based on the fact that one or both of the terms is floating
                        return [self.value compare:term.value];
                    }
                } else {
                    NSLog(@"-> not valid xsd:date lexical form");
                }
            }
            return [self.value compare:term.value];
        } else {
            if (!self.datatype) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }
    }
    return NSOrderedSame;
}

- (NSDictionary*) xsdDateComponents {
    NSRegularExpression* re = [NSRegularExpression regularExpressionWithPattern:XSD_DATE_PATTERN options:0 error:nil];
    NSTextCheckingResult* r = [re firstMatchInString:self.value options:0 range:NSMakeRange(0, [self.value length])];
    NSRange signrange       = [r rangeAtIndex: 1];
    NSRange yearrange       = [r rangeAtIndex: 2];
    NSRange monthrange      = [r rangeAtIndex: 3];
    NSRange dayrange        = [r rangeAtIndex: 4];
    NSRange tzrange         = [r rangeAtIndex: 5];
    
    NSString* tz    = @"";
    if (tzrange.location != NSNotFound) {
        tz  = [self.value substringWithRange:tzrange];
        if ([tz isEqual: @"Z"]) {
            tz  = @"+00:00";
        } else if ([tz isEqual: @"-00:00"]) {
            tz  = @"+00:00";
        } else if ([tz isEqual: @"00:00"]) {
            tz  = @"+00:00";
        }
    }
    return @{
             @"sign": [self.value substringWithRange:signrange],
             @"year": [self.value substringWithRange:yearrange],
             @"month": [self.value substringWithRange:monthrange],
             @"day": [self.value substringWithRange:dayrange],
             @"tz": tz,
             };
    
}

- (BOOL) isValidLexicalInteger {
    if (![self isInteger])
        return NO;
    NSRange range   = [self.value rangeOfString:@"([+]|-)?\\d+" options:NSRegularExpressionSearch];
    if (range.location == 0 && range.length == [self.value length]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) isValidLexicalDouble {
    if (![self isDouble])
        return NO;
    // TODO: Check lexical form
    if ([self.datatype isEqual:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
        NSRange range   = [self.value rangeOfString:@"([+]|-)?\\d+([.]\\d+)?" options:NSRegularExpressionSearch];
        if (range.location == 0 && range.length == [self.value length])
            return YES;
    } else {
        // xsd:float or xsd:double
        // TODO: We don't handle Inf or NaN here because we're using this function to know if we can use the double values in comparisons.
        NSRange range   = [self.value rangeOfString:@"([+]|-)?\\d+([.]\\d+([eE]([+]|-)?\\d+)?)?" options:NSRegularExpressionSearch];
        if (range.location == 0 && range.length == [self.value length])
            return YES;
    }
    return NO;
}

- (BOOL) isValidXSDDate {
    if (!self.datatype)
        return NO;
    if (![self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#date"])
        return NO;
    NSRange range       = [self.value rangeOfString:XSD_DATE_PATTERN options:NSRegularExpressionSearch];
    if (range.location == 0 && range.length == [self.value length])
        return YES;
    return NO;
}

- (NSUInteger)hash {
    return [[self.value description] hash];
}

- (BOOL) isInteger {
    if (!self.datatype)
        return NO;
    if ([self.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0)
        return YES;
    return NO;
}

- (BOOL) isDouble {
    if (!self.datatype)
        return NO;
    if ([self.datatype rangeOfString:@"http://www.w3.org/2001/XMLSchema#(decimal|double|float)" options:NSRegularExpressionSearch].location == 0)
        return YES;
    return NO;
}

- (BOOL) isNumeric {
//    NSLog(@"isNumeric? %@", self.datatype);
    if (!self.datatype)
        return NO;
    if ([self.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
        return YES;
    } else if ([self.datatype rangeOfString:@"http://www.w3.org/2001/XMLSchema#(decimal|double|float)" options:NSRegularExpressionSearch].location == 0) {
        return YES;
    }
    return NO;
}

+ (NSString*) promotedTypeForNumericTypes: (NSString*) lhs and: (NSString*) rhs {
    NSSet* datatypes    = [NSSet setWithObjects:lhs, rhs, nil];
    if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#double"]) {
        return @"http://www.w3.org/2001/XMLSchema#double";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#float"]) {
        return @"http://www.w3.org/2001/XMLSchema#float";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
        return @"http://www.w3.org/2001/XMLSchema#decimal";
    } else {
        NSSet* supported    = [self supportedDatatypes];
        for (NSString* type in datatypes) {
            if ([type hasPrefix:@"http://www.w3.org/2001/XMLSchema#date"]) {
                return nil;
            } else if ([supported containsObject:type]) {
                return @"http://www.w3.org/2001/XMLSchema#integer";
            }
        }
        return nil;
    }
}

- (BOOL) booleanValue {
    if (!self.datatype) {
        return NO;
    } else if (![self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#boolean"]) {
        return NO;
    } else {
        return [self.value isEqualToString:@"true"];
    }
}

- (NSInteger) integerValue {
    if (!self.datatype)
        return 0;
    if ([self.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
        long long value = atoll([self.value UTF8String]);
        return (NSInteger) value;
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
        return (NSInteger) [self doubleValue];
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#double"]) {
        return (NSInteger) [self doubleValue];
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
        return (NSInteger) [self doubleValue];
    } else {
        return 0;
    }
}

- (double) doubleValue {
    if (!self.datatype)
        return 0.0;
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#double"] || [self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
        NSDecimalNumber *decNumber = [NSDecimalNumber decimalNumberWithString:self.value];
        return [decNumber doubleValue];
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
        double v;
        sscanf([self.value UTF8String], "%lE", &v);
        return v;
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
            float v;
            sscanf([self.value UTF8String], "%f", &v);
            return (double) v;
    } else if ([self.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
        return (double) [self integerValue];
    } else {
        return 0.0;
    }
}

- (BOOL) isSimpleLiteral {
    if (self.datatype && ![self.datatype isEqual: @"http://www.w3.org/2001/XMLSchema#string"]) {
        return NO;
    }
    if (self.language) {
        return NO;
    }
    return YES;
}

- (BOOL) isArgumentCompatibileWith: (id<GTWLiteral>) literal {
    //Compatibility of two arguments is defined as:
    //
    //The arguments are simple literals or literals typed as xsd:string
    if ([self isSimpleLiteral] && [literal isSimpleLiteral]) {
        return YES;
    }

    //The arguments are plain literals with identical language tags
    if (self.language && literal.language && [self.language isEqual: literal.language]) {
        return YES;
    }
    
    //The first argument is a plain literal with language tag and the second argument is a simple literal or literal typed as xsd:string
    if (self.language && [literal isSimpleLiteral]) {
        return YES;
    }
    
    return NO;
}

- (BOOL) effectiveBooleanValueWithError: (NSError**) error {
    if (self.datatype && [self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#boolean"]) {
        BOOL ebv    = [self booleanValue];
        return ebv;
    } else if ((self.datatype && [self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#string"]) || (self.datatype && [self.datatype isEqualToString:@"http://www.w3.org/1999/02/22-rdf-syntax-ns#langString"]) || [self isSimpleLiteral]) {
        if ([self.value length] == 0) {
            return NO;
        } else {
            return YES;
        }
    } else if ([self isNumeric]) {
        NSInteger ivalue    = [self integerValue];
        if (ivalue != 0) {
            return YES;
        } else {
            double value    = [self doubleValue];
            if (value == 0.0L) {
                return NO;
            } else {
                return YES;
            }
        }
//    } else {
//        NSLog(@"EBV of unexpected value: %@", self);
    }
    
    if (error) {
        *error  =  [NSError errorWithDomain:@"us.kasei.swbase.ebv" code:1 userInfo:@{@"description": @"EBV TypeError"}];
    }
    return NO;
}

@end
