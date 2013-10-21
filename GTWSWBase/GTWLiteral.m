#import "GTWLiteral.h"

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
            if ([self.value isEqual:term.value]) {
                if ([self.language isEqual:term.language]) {
                    return YES;
                } else if (self.language || term.language) {
                    return NO;
                }
                if ([self.datatype isEqual:term.datatype]) {
                    return YES;
                } else if (self.datatype || term.datatype) {
                    return NO;
                }
                return YES;
            } else if ([self isNumeric] && [object isNumeric]) {
                if ([self doubleValue] == [object doubleValue]) {
                    return YES;
                } else if ([self integerValue] == [object integerValue]) {
                    return YES;
                } else {
                    return NO;
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

- (BOOL) isNumeric {
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#integer"])
        return YES;
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"])
        return YES;
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#double"])
        return YES;
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"])
        return YES;
    return NO;
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
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#integer"]) {
        return atoll([self.value UTF8String]);
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
    if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#double"]) {
        double v;
        sscanf([self.value UTF8String], "%lE", &v);
        return v;
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#decimal"]) {
        float v;
        sscanf([self.value UTF8String], "%f", &v);
        return (double) v;
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#float"]) {
            float v;
            sscanf([self.value UTF8String], "%f", &v);
            return (double) v;
    } else if ([self.datatype isEqualToString:@"http://www.w3.org/2001/XMLSchema#integer"]) {
        return (double) [self integerValue];
    } else {
        return 0.0;
    }
}

@end
