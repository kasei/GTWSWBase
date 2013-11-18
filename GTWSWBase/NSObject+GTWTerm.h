//
//  NSObject+GTWTerm.h
//  GTWSWBase
//
//  Created by Gregory Williams on 11/14/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTWSWBase.h"

@interface NSObject (GTWTerm)

- (BOOL) effectiveBooleanValueWithError: (NSError**) error;
- (BOOL) isValidLexicalInteger;
- (BOOL) isValidLexicalDouble;
- (BOOL) isValidXSDDate;
- (NSDictionary*) xsdDateComponents;
- (BOOL) isIntegerLiteral;
- (BOOL) isDoubleLiteral;
- (BOOL) isNumericLiteral;
- (NSInteger) integerValue;
- (double) doubleValue;
- (BOOL) isSimpleLiteral;
- (BOOL) isArgumentCompatibileWith: (id) literal;

@end
