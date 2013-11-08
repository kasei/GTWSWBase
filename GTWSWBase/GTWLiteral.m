#import "GTWLiteral.h"

static NSString* INTEGER_PATTERN = @"http://www.w3.org/2001/XMLSchema#(byte|int|integer|long|short|nonPositiveInteger|nonNegativeInteger|unsignedLong|unsignedInt|unsignedShort|unsignedByte|positiveInteger|negativeInteger)";

@implementation GTWLiteral

+ (GTWLiteral*) trueLiteral {
    return [[GTWLiteral alloc] initWithString:@"true" datatype:@"http://www.w3.org/2001/XMLSchema#boolean"];
}

+ (GTWLiteral*) falseLiteral {
    return [[GTWLiteral alloc] initWithString:@"false" datatype:@"http://www.w3.org/2001/XMLSchema#boolean"];
}

- (GTWLiteral*) copy {
    if (self.language) {
        return [[[self class] alloc] initWithString: self.value language:self.language];
    } else if (self.datatype) {
        return [[[self class] alloc] initWithString: self.value datatype:self.datatype];
    } else {
        return [[[self class] alloc] initWithValue: self.value];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

- (id) copyReplacingValues: (NSDictionary*) map {
    if (map[self])
        return map[self];
    return [self copy];
}

+ (GTWLiteral*) integerLiteralWithValue: (NSInteger) value {
    return [[GTWLiteral alloc] initWithString:[NSString stringWithFormat:@"%ld", value] datatype:@"http://www.w3.org/2001/XMLSchema#integer"];
}

+ (GTWLiteral*) doubleLiteralWithValue: (double) value {
    return [[GTWLiteral alloc] initWithString:[NSString stringWithFormat:@"%lE", value] datatype:@"http://www.w3.org/2001/XMLSchema#double"];
}

- (GTWLiteral*) initWithValue: (NSString*) value {
    return [self initWithString:value];
}

- (GTWLiteral*) initWithString: (NSString*) string {
    if (self = [self init]) {
        self.value  = string;
    }
    return self;
}

- (GTWLiteral*) initWithString: (NSString*) string language: (NSString*) language {
    if (self = [self init]) {
        self.value      = string;
        self.language   = [language lowercaseString];
        self.datatype   = @"http://www.w3.org/1999/02/22-rdf-syntax-ns#langString";
    }
    return self;
}

- (GTWLiteral*) initWithString: (NSString*) string datatype: (NSString*) datatype {
    if (self = [self init]) {
        self.value      = string;
        self.datatype   = datatype;
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
            } else if ([self isNumeric] && [object isNumeric]) {
                if ([self isDouble] || [object isDouble]) {
                    if ([self doubleValue] == [object doubleValue]) {
                        return YES;
                    } else {
                        return NO;
                    }
                } else {
                    if ([self integerValue] == [object integerValue]) {
                        return YES;
                    } else {
                        return NO;
                    }
                }
            }
        }
    }
    return NO;
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

- (NSUInteger)hash {
    return [[self.value description] hash];
}

- (BOOL) isInteger {
    if (!self.datatype)
        return NO;
    if ([self.datatype rangeOfString:INTEGER_PATTERN options:NSRegularExpressionSearch].location == 0) {
        return YES;
    }
    return NO;
}

- (BOOL) isDouble {
    if (!self.datatype)
        return NO;
    if ([self.datatype rangeOfString:@"http://www.w3.org/2001/XMLSchema#(decimal|double|float)" options:NSRegularExpressionSearch].location == 0) {
        return YES;
    }
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

+ (NSString*) promtedTypeForNumericTypes: (NSString*) lhs and: (NSString*) rhs {
//    NSLog(@"promoting type: %@ %@\n", lhs, rhs);
    NSSet* datatypes    = [NSSet setWithObjects:lhs, rhs, nil];
    if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#double"]) {
        return @"http://www.w3.org/2001/XMLSchema#double";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#float"]) {
        return @"http://www.w3.org/2001/XMLSchema#float";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
        return @"http://www.w3.org/2001/XMLSchema#decimal";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#integer"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#int"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#long"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#byte"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#short"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#nonNegativeInteger"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#nonPositiveInteger"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#unsignedLong"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#unsignedInt"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#unsignedShort"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#unsignedByte"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#positiveInteger"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else if ([datatypes containsObject:@"http://www.w3.org/2001/XMLSchema#negativeInteger"]) {
        return @"http://www.w3.org/2001/XMLSchema#integer";
    } else {
        return nil;
    }
}

- (BOOL) booleanValue {
//    NSLog(@"testing boolean value of %@", self);
    if (!self.datatype) {
//        NSLog(@"-> no datatype");
        return NO;
    } else if (![self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#boolean"]) {
//        NSLog(@"-> not a boolean datatype");
        return NO;
    } else {
//        NSLog(@"-> testing if value '%@' is 'true'", self.value);
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
//        NSLog(@"EBV %@ => %d", self, ebv);
        return ebv;
    } else if ((self.datatype && [self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#string"]) || (self.datatype && [self.datatype isEqualToString:@"http://www.w3.org/1999/02/22-rdf-syntax-ns#langString"]) || [self isSimpleLiteral]) {
//        NSLog(@"xsd:string EBV: %@", self);
        if ([self.value length] == 0) {
            return NO;
        } else {
            return YES;
        }
    } else if ([self isNumeric]) {
        NSInteger ivalue    = [self integerValue];
//        NSLog(@"EBV integer value: %ld (%d)", ivalue, (ivalue != 0));
        if (ivalue != 0) {
            return YES;
        } else {
            double value    = [self doubleValue];
//            NSLog(@"EBV double value: %lf (%d)", value, (value != 0.0L));
            if (value == 0.0L) {
                return NO;
            } else {
                return YES;
            }
        }
    } else {
//        NSLog(@"EBV of unexpected value: %@", self);
    }
    
    if (error) {
        *error  =  [NSError errorWithDomain:@"us.kasei.swbase.ebv" code:1 userInfo:@{@"description": @"EBV TypeError"}];
    }
    return NO;
}

@end
