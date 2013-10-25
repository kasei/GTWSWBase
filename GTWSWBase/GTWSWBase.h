//
//  GTWSWBase.h
//  GTWSWBase
//
//  Created by Gregory Williams on 7/31/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GTWRewriteable <NSObject>
- (id) copyReplacingValues: (NSDictionary*) map;
@end


@protocol GTWTerm <NSObject, GTWRewriteable,NSCopying>
/// The type of an Term object (including RDF Term types as well as variables)
typedef NS_ENUM(NSInteger, GTWTermType) {
    GTWTermIRI,
    GTWTermBlank,
    GTWTermLiteral,
    GTWTermVariable,
};
- (id<GTWTerm>) initWithValue: (NSString*) value;
- (GTWTermType) termType;
- (NSString*) value;
- (NSComparisonResult)compare:(id<GTWTerm>)term;
@optional
- (NSString*) language;
- (NSString*) datatype;
@end

@protocol GTWBlank <GTWTerm>
@end

@protocol GTWIRI <GTWTerm>
@end

@protocol GTWLiteral <GTWTerm>
- (NSString*) datatype;
- (NSString*) language;
- (BOOL) isNumeric;
- (BOOL) booleanValue;
- (NSInteger) integerValue;
- (double) doubleValue;
@end

@protocol GTWVariable <GTWTerm>
@end

@protocol GTWTriple <NSObject>
@property id<GTWTerm> subject;
@property id<GTWTerm> predicate;
@property id<GTWTerm> object;
- (NSArray*) allValues;
@end

@protocol GTWQuad <GTWTriple>
@property id<GTWTerm> subject;
@property id<GTWTerm> predicate;
@property id<GTWTerm> object;
@property id<GTWTerm> graph;
@end

@protocol GTWDataSource <NSObject>
- (unsigned)interfaceVersion;
- (instancetype) initWithDictionary: (NSDictionary*) dictionary;
@end

#pragma mark -
#pragma mark Triple Store Protocols

@protocol GTWTripleStore <NSObject>
- (NSArray*) getTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
- (BOOL) enumerateTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o usingBlock: (void (^)(id<GTWTriple> t)) block error:(NSError **)error;
@optional
- (NSEnumerator*) tripleEnumeratorMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
- (NSString*) etagForTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
- (NSUInteger) countTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
@end

@protocol GTWMutableTripleStore <NSObject>
- (BOOL) addTriple: (id<GTWTriple>) t error:(NSError **)error;
- (BOOL) removeTriple: (id<GTWTriple>) t error:(NSError **)error;
@end

#pragma mark -
#pragma mark Quad Store Protocols

@protocol GTWQuadStore <NSObject>
- (NSArray*) getGraphsWithOutError:(NSError **)error;
- (BOOL) enumerateGraphsUsingBlock: (void (^)(id<GTWTerm> g)) block error:(NSError **)error;
- (NSArray*) getQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
- (BOOL) enumerateQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g usingBlock: (void (^)(id<GTWQuad> q)) block error:(NSError **)error;
@optional
- (NSEnumerator*) quadEnumeratorMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
- (BOOL) addIndexType: (NSString*) type value: (NSArray*) positions synchronous: (BOOL) sync error: (NSError**) error;
- (NSString*) etagForQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
- (NSUInteger) countGraphsWithOutError:(NSError **)error;
- (NSUInteger) countQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
@end

@protocol GTWMutableQuadStore <NSObject>
- (BOOL) addQuad: (id<GTWQuad>) q error:(NSError **)error;
- (BOOL) removeQuad: (id<GTWQuad>) q error:(NSError **)error;
@end


#pragma mark -

@protocol GTWModel <NSObject>
- (NSEnumerator*) quadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g  error:(NSError **)error;
- (BOOL) enumerateGraphsUsingBlock: (void (^)(id<GTWTerm> g)) block error:(NSError **)error;
- (BOOL) enumerateQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g usingBlock: (void (^)(id<GTWQuad> q)) block error:(NSError **)error;
- (BOOL) enumerateBindingsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g usingBlock: (void (^)(NSDictionary* q)) block error:(NSError **)error;
- (NSArray*) objectsForSubject: (id<GTWTerm>) subject predicate: (id<GTWTerm>) predicate graph: (id<GTWTerm>) graph;
- (id<GTWTerm>) anyObjectForSubject: (id<GTWTerm>) subject predicate: (id<GTWTerm>) predicate graph: (id<GTWTerm>) graph;
@end

#pragma mark -

@protocol GTWDataset <NSObject>
- (NSArray*) defaultGraphs;
- (NSArray*) availableGraphsFromModel: (id<GTWModel>) model;
@end

#pragma mark -

extern NSString* __strong const kGTWMediaTypeNTriples;
extern NSString* __strong const kGTWMediaTypeNQuads;
extern NSString* __strong const kGTWMediaTypeTurtle;
extern NSString* __strong const kGTWMediaTypeRDFXML;
extern NSString* __strong const kGTWMediaTypeRDFJSON;
extern NSString* __strong const kGTWMediaTypeTriG;
extern NSString* __strong const kGTWMediaTypeRDFPatch;
extern NSString* __strong const kGTWMediaTypeCSV;
extern NSString* __strong const kGTWMediaTypeSPARQLXML;
extern NSString* __strong const kGTWMediaTypeSPARQLJSON;
extern NSString* __strong const kGTWMediaTypeTSV;

//extern NSString* __strong const kGTWTypeTriples;
//extern NSString* __strong const kGTWTypeQuads;
//extern NSString* __strong const kGTWTypeMixedTriplesAndQuads;
//extern NSString* __strong const kGTWTypeSPARQLResults;
//extern NSString* __strong const kGTWTypeOperations;
//extern NSString* __strong const kGTWTypeBytes;

typedef NS_ENUM(NSInteger, GTWType) {
    GTWTypeTriple,
    GTWTypeQuads,
    GTWTypeMixedTriplesAndQuads,
    GTWTypeSPARQLResults,
    GTWTypeOperations,
    GTWTypeBytes,
};

#define MAP_ENUM_TO_STRING(x) @(x): @#x

//NSDictionary* map  = @{
//                                    MAP_ENUM_TO_STRING(GTWTypeTriple),
//                                    MAP_ENUM_TO_STRING(GTWTypeQuads),
//                                    MAP_ENUM_TO_STRING(GTWTypeMixedTriplesAndQuads),
//                                    MAP_ENUM_TO_STRING(GTWTypeSPARQLResults),
//                                    MAP_ENUM_TO_STRING(GTWTypeOperations),
//                                    MAP_ENUM_TO_STRING(GTWTypeBytes),
//};

@protocol GTWSerializer <NSObject>
@end

@protocol GTWTriplesSerializer <GTWSerializer>
- (NSData*) dataFromTriples: (NSEnumerator*) triples;
- (void) serializeTriples: (NSEnumerator*) triples toHandle: (NSFileHandle*) handle;
@end

@protocol GTWQuadsSerializer <GTWSerializer>
- (NSData*) dataFromQuads: (NSEnumerator*) triples;
- (void) serializeQuads: (NSEnumerator*) quads toHandle: (NSFileHandle*) handle;
@end

@protocol GTWMixedSerializer <GTWSerializer>
- (NSData*) dataFromTriplesAndQuads: (NSEnumerator*) statements;
- (void) serializeTriplesAndQuads: (NSEnumerator*) statements toHandle: (NSFileHandle*) handle;
@end

@protocol GTWSPARQLResultsSerializer <GTWSerializer>
- (NSData*) dataFromResults: (NSEnumerator*) results withVariables: (NSSet*) variables;
- (void) serializeResults: (NSEnumerator*) results withVariables: (NSSet*) variables toHandle: (NSFileHandle*) handle;
@end

@protocol GTWOperationsSerializer <GTWSerializer>
- (NSData*) dataFromOperations: (NSEnumerator*) ops;
- (void) serializeOperations: (NSEnumerator*) ops toHandle: (NSFileHandle*) handle;
@end

@protocol GTWParser <NSObject>
@end

@protocol GTWSPARQLResultsParser <GTWParser>
- (NSEnumerator*) parseResultsFromData: (NSData*) data settingVariables: (NSMutableSet*) set;
@end

