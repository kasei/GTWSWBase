//
//  GTWSPARQLResultsXMLParser.m
//  GTWSPARQLEngine
//
//  Created by Gregory Williams on 9/23/13.
//  Copyright (c) 2013 Gregory Williams. All rights reserved.
//

#import "GTWSPARQLResultsXMLParser.h"
#import "GTWIRI.h"
#import "GTWLiteral.h"
#import "GTWBlank.h"

@interface GTWSPARQLResultsXMLParserError : NSError
@end
@implementation GTWSPARQLResultsXMLParserError
- (NSString*) localizedDescription { return self.userInfo[@"description"]; }
@end

@implementation GTWSPARQLResultsXMLParser

+ (NSSet*) handledParserMediaTypes {
    return [NSSet setWithObjects:@"application/sparql-results+xml", nil];
}

+ (NSSet*) handledFileExtensions {
    return [NSSet setWithObjects:@".srx", @".xml", nil];
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

- (GTWSPARQLResultsXMLParser*) initWithData: (NSData*) data base: (GTWIRI*) base {
    if (self = [self init]) {
        self.data   = data;
    }
    return self;
}

- (BOOL) parseResultsFromData: (NSData*) data settingVariables: (NSMutableSet*) set withBlock: (void (^)(NSDictionary*)) block error:(NSError**)error {
    self.parseError = nil;
    NSEnumerator* e = [self parseResultsFromData:data settingVariables:set];
    for (NSDictionary* r in e) {
        block(r);
    }
    if (self.parseError) {
        *error = self.parseError;
        return NO;
    } else {
        return YES;
    }
}

- (NSEnumerator*) parseResultsFromData: (NSData*) data settingVariables: (NSMutableSet*) set {
    self.parseError = nil;
    self.data   = data;
    NSXMLParser * parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    self.variables  = set;
    [parser parse];
    if (self.parseError) {
        return nil;
    } else {
        return [self.results objectEnumerator];
    }
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.results    = [NSMutableArray array];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqual: @"variable"]) {
        NSString* var = attributeDict[@"name"];
        if (var) {
            [self.variables addObject:var];
        }
    } else if ([elementName isEqual: @"result"]) {
        self.result = [NSMutableDictionary dictionary];
    } else if ([elementName isEqual: @"boolean"]) {
        self.currentValue   = [NSMutableString string];
        self.result = [NSMutableDictionary dictionary];
    } else if ([elementName isEqual: @"binding"]) {
        self.currentVariable    = attributeDict[@"name"];
    } else if ([elementName isEqual: @"uri"]) {
        self.currentValue   = [NSMutableString string];
    } else if ([elementName isEqual: @"bnode"]) {
        self.currentValue   = [NSMutableString string];
    } else if ([elementName isEqual: @"literal"]) {
        self.currentValue   = [NSMutableString string];
        self.datatype       = attributeDict[@"datatype"];
        self.language       = attributeDict[@"xml:lang"];
    } else if ([elementName isEqual: @"results"]) {
    } else if ([elementName isEqual: @"head"]) {
    } else if ([elementName isEqual: @"sparql"]) {
    } else {
        NSString* d     = [NSString stringWithFormat:@"Unexpected XML tag <%@>", elementName];
        self.parseError = [GTWSPARQLResultsXMLParserError errorWithDomain:@"us.kasei.sparqlkit.rdf-xml.parse-error" code:0 userInfo:@{@"description": d}];
//        NSLog(@"<%@>", elementName);
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqual: @"uri"]) {
        [self.result setObject:[[GTWIRI alloc] initWithValue:self.currentValue] forKey:self.currentVariable];
        self.currentValue   = nil;
    } else if ([elementName isEqual: @"boolean"]) {
        [self.result setObject:[[GTWLiteral alloc] initWithValue:self.currentValue datatype:@"http://www.w3.org/2001/XMLSchema#boolean"] forKey:@".bool"];
        [self.results addObject: self.result];
        self.currentValue   = nil;
    } else if ([elementName isEqual: @"bnode"]) {
        [self.result setObject:[[GTWBlank alloc] initWithValue:self.currentValue] forKey:self.currentVariable];
        self.currentValue   = nil;
    } else if ([elementName isEqual: @"literal"]) {
        if (self.datatype) {
            [self.result setObject:[[GTWLiteral alloc] initWithValue:self.currentValue datatype:self.datatype] forKey:self.currentVariable];
        } else if (self.language) {
            [self.result setObject:[[GTWLiteral alloc] initWithValue:self.currentValue language:self.language] forKey:self.currentVariable];
        } else {
            [self.result setObject:[[GTWLiteral alloc] initWithValue:self.currentValue] forKey:self.currentVariable];
        }
        self.currentValue   = nil;
    } else if ([elementName isEqual: @"result"]) {
        [self.results addObject: self.result];
    } else if ([elementName isEqual: @"sparql"]) {
    } else if ([elementName isEqual: @"head"]) {
    } else if ([elementName isEqual: @"variable"]) {
    } else if ([elementName isEqual: @"results"]) {
    } else if ([elementName isEqual: @"binding"]) {
    } else {
        NSString* d     = [NSString stringWithFormat:@"Unexpected XML tag </%@>", elementName];
        self.parseError = [GTWSPARQLResultsXMLParserError errorWithDomain:@"us.kasei.sparqlkit.rdf-xml.parse-error" code:1 userInfo:@{@"description": d}];
//        NSLog(@"</%@>", elementName);
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"XML parse error: %@", parseError);
    self.parseError = parseError;
}

@end
