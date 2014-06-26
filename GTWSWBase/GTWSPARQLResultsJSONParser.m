//
//  GTWSPARQLResultsJSONParser.m
//  GTWSWBase
//
//  Created by Gregory Williams on 10/30/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import "GTWSPARQLResultsJSONParser.h"
#import "GTWLiteral.h"
#import "GTWBlank.h"
#import "GTWIRI.h"

@implementation GTWSPARQLResultsJSONParser

+ (NSSet*) handledParserMediaTypes {
    return [NSSet setWithObjects:@"application/sparql-results+json", nil];
}

+ (NSSet*) handledFileExtensions {
    return [NSSet setWithObjects:@".srj", @".json", nil];
}

+ (unsigned)interfaceVersion {
    return 0;
}

+ (NSDictionary*) classesImplementingProtocols {
    return @{ (id)self: [self implementedProtocols] };
}

+ (NSSet*) implementedProtocols {
    return [NSSet setWithObjects:@protocol(GTWSPARQLResultsParser), nil];
}

- (GTWSPARQLResultsJSONParser*) initWithData: (NSData*) data base: (GTWIRI*) base {
    if (self = [self init]) {
        self.data   = data;
    }
    return self;
}

- (BOOL) parseResultsFromData: (NSData*) data settingVariables: (NSMutableSet*) set withBlock: (void (^)(NSDictionary*)) block error:(NSError**)error {
    NSEnumerator* e = [self parseResultsFromData:data settingVariables:set];
    for (NSDictionary* r in e) {
        block(r);
    }
    return YES;
}

- (NSEnumerator*) parseResultsFromData: (NSData*) data settingVariables: (NSMutableSet*) set {
    NSError* error  = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//    NSLog(@"JSON data: %@", json);
    if (error) {
        NSLog(@"SPARQL-JSON Parsing error: %@", error);
        return nil;
    }
    
    NSNumber* boolean   = json[@"boolean"];
    if (boolean) {
        if ([boolean boolValue]) {
            NSDictionary* result    = @{@".bool": [GTWLiteral trueLiteral]};
            return [@[result] objectEnumerator];
        } else {
            NSDictionary* result    = @{@".bool": [GTWLiteral falseLiteral]};
            return [@[result] objectEnumerator];
        }
    } else {
        [set addObjectsFromArray:json[@"head"][@"vars"]];
        NSDictionary* r     = json[@"results"];
        NSArray* bindings   = r[@"bindings"];
        NSMutableArray* results = [NSMutableArray array];
        for (NSDictionary* resultData in bindings) {
    //        NSLog(@"RESULT DATA: %@", resultData);
            NSMutableDictionary* result = [NSMutableDictionary dictionary];
            NSArray* keys   = [resultData allKeys];
            for (NSString* key in keys) {
                NSDictionary* termData  = resultData[key];
                NSString* type  = termData[@"type"];
                id<GTWTerm> term    = nil;
                if ([type isEqual: @"uri"]) {
                    term    = [[GTWIRI alloc] initWithValue:termData[@"value"]];
                } else if ([type isEqual: @"literal"] || [type isEqual: @"typed-literal"]) {
                    if (termData[@"xml:lang"]) {
                        term    = [[GTWLiteral alloc] initWithValue:termData[@"value"] language:termData[@"xml:lang"]];
                    } else if (termData[@"datatype"]) {
                        term    = [[GTWLiteral alloc] initWithValue:termData[@"value"] datatype:termData[@"datatype"]];
                    } else {
                        term    = [[GTWLiteral alloc] initWithValue:termData[@"value"]];
                    }
                } else if ([type isEqual: @"bnode"]) {
                    term    = [[GTWBlank alloc] initWithValue:termData[@"value"]];
                } else {
                    NSLog(@"Can't turn JSON object into an RDF Term: %@", termData);
                }
                if (!term)
                    return nil;
                result[key] = term;
            }
            [results addObject:result];
        }
//        NSLog(@"JSON Parsed object: %@", json);
        return [results objectEnumerator];
    }
}

@end
