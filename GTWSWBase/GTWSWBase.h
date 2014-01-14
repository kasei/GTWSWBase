//
//  GTWSWBase.h
//  GTWSWBase
//
//  Created by Gregory Williams on 7/31/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+GTWTerm.h"

typedef NS_ENUM(NSInteger, GTWDatasetAvailability) {
    GTWFullDataset,
    GTWRestrictedDataset
};



@protocol GTWRewriteable <NSObject>
- (id) copyReplacingValues: (NSDictionary*) map;
- (id) copyWithCanonicalization;
@end


@protocol GTWTerm <NSObject,GTWRewriteable,NSCopying>
/// The type of an Term object (including RDF Term types as well as variables)
typedef NS_ENUM(NSInteger, GTWTermType) {
    GTWTermIRI,
    GTWTermBlank,
    GTWTermLiteral,
    GTWTermVariable,
};
/**
 @param value
 The lexical value of the term to be initialized.
 @return A GTWTerm object.
 */
- (id<GTWTerm>) initWithValue: (NSString*) value;
- (GTWTermType) termType;
- (BOOL) effectiveBooleanValueWithError: (NSError**) error;

/**
 Returns a Boolean value that indicates whether the receiver and a given object have values that are equal in their respective value-space.
 */
- (BOOL) isValueEqual:(id<GTWTerm>)object;
/**
 @return The lexical value of the RDF Term.
 */
- (NSString*) value;

- (NSComparisonResult)compare:(id<GTWTerm>)term;
@optional
/**
 @return The language tag of the RDF Term.
 */
- (NSString*) language;

/**
 @return The datatype URI string of the RDF Term.
 */
- (NSString*) datatype;
@end



@protocol GTWBlank <GTWTerm>
@end



@protocol GTWIRI <GTWTerm>
@end



@protocol GTWLiteral <GTWTerm>
/**
 @return The datatype URI string of the RDF Term.
 */
- (NSString*) datatype;

/**
 @return The language tag of the RDF Term.
 */
- (NSString*) language;

/**
 @return @c YES if the RDF Term is a recognized XSD numeric type. @c FALSE otherwise.
 */
- (BOOL) isNumericLiteral;
- (BOOL) isDoubleLiteral;
- (BOOL) isIntegerLiteral;

/**
 @return @c YES if the RDF Term is a xsd:boolean literal and true. @c NO otherwise.
 */
- (BOOL) booleanValue;

/**
 @return The integer value of a recognized XSD numeric RDF Term.
 */
- (NSInteger) integerValue;

/**
 @return The double value of a recognized XSD numeric RDF Term.
 */
- (double) doubleValue;

- (BOOL) isSimpleLiteral;
- (BOOL) isArgumentCompatibileWith: (id<GTWLiteral>) literal;

@end



@protocol GTWVariable <GTWTerm>
@end


@protocol GTWStatement <NSObject,GTWRewriteable>
/**
 @return An array of the subject, predicate, and object RDF Term objects.
 */
- (NSArray*) allValues;

/**
 @return @c YES is the triple's subject, predicate, and object values are all either IRIs, Literals, or Blanks (not Variables). @c NO otherwise.
 */
- (BOOL) isGround;
@end

@protocol GTWTriple <GTWStatement,NSCopying>
@property id<GTWTerm> subject;
@property id<GTWTerm> predicate;
@property id<GTWTerm> object;
@end



@protocol GTWQuad <GTWTriple,NSCopying>
@property id<GTWTerm> subject;
@property id<GTWTerm> predicate;
@property id<GTWTerm> object;
@property id<GTWTerm> graph;
@end


@protocol GTWPlugin <NSObject>
/**
 @return
 The API version number implemented by the data source.
 */
+ (unsigned)interfaceVersion;

/**
 A dictionary mapping plugin class objects to a set of protocols that are implemented by that class.
 */
+ (NSDictionary*) classesImplementingProtocols;

/**
 @return
 A set of @c Protocol objects that are implemented by the plugin.
 */
+ (NSSet*) implementedProtocols;

@end


@protocol GTWDataSource <NSObject,GTWPlugin>
/**
 @param dictionary
 A dictionary containing data source specific initialization information.
 See the @c usage method for a way to access a description of the expected format of this dictionary.
 */
- (id<GTWDataSource>) initWithDictionary: (NSDictionary*) dictionary;

/**
 @return A string containing a template description of the expected values to be passed
 to @c initWithDictionary: in order to properly initialize the data source.
 */
+ (NSString*)usage;

@end



#pragma mark -
#pragma mark Triple Store Protocols

@protocol GTWTripleStore <NSObject>
/**
 @param s
 A id<GTWTerm> object constraining the results to only triples whose subject equals @c s.
 Using @c nil will allow enumeration of triples with any subject.

 @param p
 A id<GTWTerm> object constraining the results to only triples whose predicate equals @c p.
 Using @c nil will allow enumeration of triples with any predicate.

 @param o
 A id<GTWTerm> object constraining the results to only triples whose object equals @c o.
 Using @c nil will allow enumeration of triples with any object.
 
 @param error
 A pointer to an error object that is set if the matching fails.
 
 @return An array of all triples matching the supplied constraint terms.
 */
- (NSArray*) getTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;

/**
 @param s
 A id<GTWTerm> object constraining the enumeration to only triples whose subject equals @c s.
 Using @c nil will allow enumeration of triples with any subject.
 
 @param p
 A id<GTWTerm> object constraining the enumeration to only triples whose predicate equals @c p.
 Using @c nil will allow enumeration of triples with any predicate.
 
 @param o
 A id<GTWTerm> object constraining the enumeration to only triples whose object equals @c o.
 Using @c nil will allow enumeration of triples with any object.

 @param block
 A block called with each triple matching the supplied constraint terms.
 
 @param error
 A pointer to an error object that is set if the matching fails.
*/
- (BOOL) enumerateTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o usingBlock: (void (^)(id<GTWTriple> t)) block error:(NSError **)error;
@optional
- (NSEnumerator*) tripleEnumeratorMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
- (NSString*) etagForTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
- (NSDate*) lastModifiedDateForTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
- (NSUInteger) countTriplesMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o error:(NSError **)error;
@end

@protocol GTWMutableTripleStore <NSObject>
/**
 @param t
 A id<GTWTriple> object to add to the triple store.
 
 @param error
 A pointer to an error object that is set if the addition fails.
 
 */
- (BOOL) addTriple: (id<GTWTriple>) t error:(NSError **)error;

/**
 @param t
 A id<GTWTriple> object to remove from the triple store.
 
 @param error
 A pointer to an error object that is set if the addition fails.
 
 */
- (BOOL) removeTriple: (id<GTWTriple>) t error:(NSError **)error;
@end

#pragma mark -
#pragma mark Quad Store Protocols

@protocol GTWQuadStore <NSObject>
/**
 @param error
 A pointer to an error object that is set if the matching fails.

 @return An array of all graph terms that exist in the quad store.
 */
- (NSArray*) getGraphsWithError:(NSError **)error;

/**
 @param block
 A block called with each graph term that exists in the quad store.

 @param error
 A pointer to an error object that is set if the matching fails.
*/
- (BOOL) enumerateGraphsUsingBlock: (void (^)(id<GTWTerm> g)) block error:(NSError **)error;

/**
 @param s
 A id<GTWTerm> object constraining the results to only quads whose subject equals @c s.
 Using @c nil will allow enumeration of quads with any subject.
 
 @param p
 A id<GTWTerm> object constraining the results to only quads whose predicate equals @c p.
 Using @c nil will allow enumeration of quads with any predicate.
 
 @param o
 A id<GTWTerm> object constraining the results to only quads whose object equals @c o.
 Using @c nil will allow enumeration of quads with any object.
 
 @param g
 A id<GTWTerm> object constraining the results to only quads whose graph equals @c g.
 Using @c nil will allow enumeration of quads with any graph.
 
 @param error
 A pointer to an error object that is set if the matching fails.
 
 @return An array of all triples matching the supplied constraint terms.
 */
- (NSArray*) getQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;

/**
 @param s
 A id<GTWTerm> object constraining the enumeration to only quads whose subject equals @c s.
 Using @c nil will allow enumeration of quads with any subject.
 
 @param p
 A id<GTWTerm> object constraining the enumeration to only quads whose predicate equals @c p.
 Using @c nil will allow enumeration of quads with any predicate.
 
 @param o
 A id<GTWTerm> object constraining the enumeration to only quads whose object equals @c o.
 Using @c nil will allow enumeration of quads with any object.
 
 @param g
 A id<GTWTerm> object constraining the enumeration to only quads whose graph equals @c g.
 Using @c nil will allow enumeration of quads with any graph.
 
 @param block
 A block called with each quad matching the supplied constraint terms.
 
 @param error
 A pointer to an error object that is set if the matching fails.
 
 */
- (BOOL) enumerateQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g usingBlock: (void (^)(id<GTWQuad> q)) block error:(NSError **)error;
@optional
- (NSEnumerator*) quadEnumeratorMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
- (BOOL) addIndexType: (NSString*) type value: (NSArray*) positions synchronous: (BOOL) sync error: (NSError**) error;
- (NSString*) etagForQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
- (NSDate*) lastModifiedDateForQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
- (NSUInteger) countGraphsWithError:(NSError **)error;
- (NSUInteger) countQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
@end

@protocol GTWMutableQuadStore <NSObject>
/**
 @param q
 A id<GTWQuad> object to add to the quad store.
 
 @param error
 A pointer to an error object that is set if the addition fails.
 
 */

- (BOOL) addQuad: (id<GTWQuad>) q error:(NSError **)error;

/**
 @param q
 A id<GTWQuad> object to remove from the quad store.
 
 @param error
 A pointer to an error object that is set if the addition fails.
 
 */
- (BOOL) removeQuad: (id<GTWQuad>) q error:(NSError **)error;
@end


#pragma mark -

@protocol GTWModel <NSObject>
/**
 @param s
 A id<GTWTerm> object constraining the enumeration to only quads whose subject equals @c s.
 Using @c nil will allow enumeration of quads with any subject.
 
 @param p
 A id<GTWTerm> object constraining the enumeration to only quads whose predicate equals @c p.
 Using @c nil will allow enumeration of quads with any predicate.
 
 @param o
 A id<GTWTerm> object constraining the enumeration to only quads whose object equals @c o.
 Using @c nil will allow enumeration of quads with any object.
 
 @param g
 A id<GTWTerm> object constraining the enumeration to only quads whose graph equals @c g.
 Using @c nil will allow enumeration of quads with any graph.
 
 @param error
 A pointer to an error object that is set if the matching fails.

 @return
 An enumerator of id<GTWQuad> objects matching the supplied constraint terms.
 */
- (NSEnumerator*) quadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g  error:(NSError **)error;

/**
 @param block
 A block called with each graph term that exists in the quad store.

 @param error
 A pointer to an error object that is set if the matching fails.
 
 */
- (BOOL) enumerateGraphsUsingBlock: (void (^)(id<GTWTerm> g)) block error:(NSError **)error;

/**
 @param s
 A id<GTWTerm> object constraining the enumeration to only quads whose subject equals @c s.
 Using @c nil will allow enumeration of quads with any subject.
 
 @param p
 A id<GTWTerm> object constraining the enumeration to only quads whose predicate equals @c p.
 Using @c nil will allow enumeration of quads with any predicate.
 
 @param o
 A id<GTWTerm> object constraining the enumeration to only quads whose object equals @c o.
 Using @c nil will allow enumeration of quads with any object.
 
 @param g
 A id<GTWTerm> object constraining the enumeration to only quads whose graph equals @c g.
 Using @c nil will allow enumeration of quads with any graph.
 
 @param error
 A pointer to an error object that is set if the matching fails.
 
 @param block
 A block called with each quad matching the supplied constraint terms.
 */
- (BOOL) enumerateQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g usingBlock: (void (^)(id<GTWQuad> q)) block error:(NSError **)error;

/**
 @param s
 A id<GTWTerm> object constraining the enumeration to only quads whose subject equals @c s.
 If @c s is a id<GTWVariable> term, the results will contain bindings from the variable name
 to the subjects of quads in the model.
 
 @param p
 A id<GTWTerm> object constraining the enumeration to only quads whose predicate equals @c p.
 If @c p is a id<GTWVariable> term, the results will contain bindings from the variable name
 to the predicates of quads in the model.
 
 @param o
 A id<GTWTerm> object constraining the enumeration to only quads whose object equals @c o.
 If @c o is a id<GTWVariable> term, the results will contain bindings from the variable name
 to the objects of quads in the model.
 
 @param g
 A id<GTWTerm> object constraining the enumeration to only quads whose graph equals @c g.
 If @c g is a id<GTWVariable> term, the results will contain bindings from the variable name
 to the graphs of quads in the model.
 
 @param block
 A block called with for each quad matching the supplied constraint terms, passing a dictionary
 of bindings from variable names to RDF terms.

 @param error
 A pointer to an error object that is set if the matching fails.
*/
- (BOOL) enumerateBindingsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g usingBlock: (void (^)(NSDictionary* q)) block error:(NSError **)error;

/**
 @param s
 A id<GTWTerm> object constraining the matching to only quads whose subject equals @c s.
 Using @c nil will allow matching of quads with any subject.
 
 @param p
 A id<GTWTerm> object constraining the matching to only quads whose predicate equals @c p.
 If @c p is a id<GTWVariable> term, the results will contain bindings from the variable name
 Using @c nil will allow matching of quads with any predicate.
 
 @param g
 A id<GTWTerm> object constraining the matching to only quads whose graph equals @c g.
 Using @c nil will allow matching of quads with any graph.
 
 @return
 An array of objects from quads matching the supplied term constraints.
 */
- (NSArray*) objectsForSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p graph: (id<GTWTerm>) g;

/**
 @param s
 A id<GTWTerm> object constraining the matching to only quads whose subject equals @c s.
 Using @c nil will allow matching of quads with any subject.
 
 @param p
 A id<GTWTerm> object constraining the matching to only quads whose predicate equals @c p.
 Using @c nil will allow matching of quads with any predicate.
 
 @param g
 A id<GTWTerm> object constraining the matching to only quads whose graph equals @c g.
 Using @c nil will allow matching of quads with any graph.
 
 @return
 One object from quads matching the supplied term constraints. If there are more than one
 matching quads, which object is returned is undefined. If no quads match the term constraints,
 @c nil is returned.
 */
- (id<GTWTerm>) anyObjectForSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p graph: (id<GTWTerm>) g;

- (NSDate*) lastModifiedDateForQuadsMatchingSubject: (id<GTWTerm>) s predicate: (id<GTWTerm>) p object: (id<GTWTerm>) o graph: (id<GTWTerm>) g error:(NSError **)error;
@end

@protocol GTWMutableModel <NSObject>
/**
 @param q
 A id<GTWQuad> object to add to the quad store.
 
 @param error
 A pointer to an error object that is set if the addition fails.
 
 */

- (BOOL) addQuad: (id<GTWQuad>) q error:(NSError **)error;

/**
 @param q
 A id<GTWQuad> object to remove from the quad store.
 
 @param error
 A pointer to an error object that is set if the addition fails.
 
 */
- (BOOL) removeQuad: (id<GTWQuad>) q error:(NSError **)error;

- (BOOL) createGraph: (id<GTWIRI>) graph error:(NSError **)error;
- (BOOL) dropGraph: (id<GTWIRI>) graph error:(NSError **)error;
- (BOOL) clearGraph: (id<GTWIRI>) graph error:(NSError **)error;

@end

#pragma mark -

@protocol GTWDataset <NSObject>
@property GTWDatasetAvailability availabilityType;
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

@protocol GTWSerializerDelegate <NSObject>
- (NSString*) stringFromObject: (id) object;
@end

@protocol GTWSerializer <NSObject>
@property id<GTWSerializerDelegate> delegate;
@end

@protocol GTWTriplesSerializer <GTWSerializer>
/**
 @param triples
       An enumerator returning id<GTWTriple> objects.
 @return The serialization of the RDF graph made up of the enumerated triples.
 */
- (NSData*) dataFromTriples: (NSEnumerator*) triples;

/**
 @param triples
 An enumerator returning id<GTWTriple> objects.
 @param handle
 A FileHandle to which the serialized RDF graph made up of the enumerated triples is written.
 */
- (void) serializeTriples: (NSEnumerator*) triples toHandle: (NSFileHandle*) handle;
@end



@protocol GTWQuadsSerializer <GTWSerializer>
/**
 @param quads
 An enumerator returning id<GTWQuad> objects.
 @return The serialization of the RDF graphs made up of the enumerated quads.
 */
- (NSData*) dataFromQuads: (NSEnumerator*) quads;

/**
 @param quads
 An enumerator returning id<GTWQuad> objects.
 @param handle
 A FileHandle to which the serialized RDF graphs made up of the enumerated quads is written.
 */
- (void) serializeQuads: (NSEnumerator*) quads toHandle: (NSFileHandle*) handle;
@end



@protocol GTWMixedSerializer <GTWSerializer>
/**
 @param statements
 An enumerator returning id<GTWTriple> and/or id<GTWQuad> objects.
 @return The serialization of the RDF graph(s) made up of the enumerated statements.
 */
- (NSData*) dataFromTriplesAndQuads: (NSEnumerator*) statements;

/**
 @param statements
 An enumerator returning id<GTWTriple> and/or id<GTWQuad> objects.
 @param handle
 A FileHandle to which the serialized RDF graph(s) made up of the enumerated statements are written.
 */
- (void) serializeTriplesAndQuads: (NSEnumerator*) statements toHandle: (NSFileHandle*) handle;
@end




@protocol GTWSPARQLResultsSerializer <GTWSerializer>
/**
 @param results
 An enumerator returning SPARQL Result (@c NSDictionary*) objects.
 @param variables
 A set of variable names that should be used during serialization.
 @return The serialization of the enumerated SPARQL results.
 */
- (NSData*) dataFromResults: (NSEnumerator*) results withVariables: (NSSet*) variables;

/**
 @param results
 An enumerator returning SPARQL Result (@c NSDictionary*) objects.
 @param variables
 A set of variable names that should be used during serialization.
 @param handle
 A FileHandle to which the enumerated SPARQL results are written.
 */
- (void) serializeResults: (NSEnumerator*) results withVariables: (NSSet*) variables toHandle: (NSFileHandle*) handle;
@end




@protocol GTWOperationsSerializer <GTWSerializer>
- (NSData*) dataFromOperations: (NSEnumerator*) ops;
- (void) serializeOperations: (NSEnumerator*) ops toHandle: (NSFileHandle*) handle;
@end

@protocol GTWParser <NSObject>
- (id<GTWParser>) initWithData: (NSData*) data base: (id<GTWIRI>) base;
+ (NSSet*) handledParserMediaTypes;
+ (NSSet*) handledFileExtensions;
@end

@protocol GTWSPARQLResultsParser <GTWParser>
- (NSEnumerator*) parseResultsFromData: (NSData*) data settingVariables: (NSMutableSet*) set;
@end

#pragma mark -

@protocol GTWRDFParser<GTWParser>
@property (readwrite) id<GTWIRI> baseURI;
- (BOOL) enumerateTriplesWithBlock: (void (^)(id<GTWTriple> t)) block error:(NSError **)error;
@end


