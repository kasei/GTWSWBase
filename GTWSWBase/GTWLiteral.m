#import "GTWLiteral.h"
#import "NSObject+GTWTerm.h"

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

+ (GTWLiteral*) decimalLiteralWithValue: (double) value {
    return [[GTWLiteral alloc] initWithValue:[NSString stringWithFormat:@"%lf", value] datatype:@"http://www.w3.org/2001/XMLSchema#decimal"];
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
                if ([self isIntegerLiteral]) {
                    self.value  = [NSString stringWithFormat:@"%ld", [self integerValue]];
                } else if ([self isDoubleLiteral]) {
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
            if ([self isNumericLiteral] && [literal isNumericLiteral]) {
                if ([self isDoubleLiteral] || [literal isDoubleLiteral]) {
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

+ (BOOL) literal: (NSObject<GTWLiteral>*) l isComparableWith: (id<GTWLiteral>) term {
    if (!term)
        return NO;
    if (l.termType != term.termType) {
        return YES;
    } else {
        id<GTWLiteral> literal  = (id<GTWLiteral>) term;
        if (!l.datatype && !term.datatype) {
            return YES;
        } else if ([l isNumericLiteral] && [literal isNumericLiteral]) {
            if ([l isIntegerLiteral]) {
                if (![l isValidLexicalInteger]) {
                    return NO;
                }
            }
            if ([l isDoubleLiteral]) {
                if (![l isValidLexicalDouble]) {
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
        } else if ([self isNumericLiteral] && [literal isNumericLiteral]) {
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

- (NSUInteger)hash {
    return [[self.value description] hash];
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

@end
