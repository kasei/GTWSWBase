//
//  IRI.m
//  GTWSWBase
//
//  Created by Gregory Williams on 11/13/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import "IRI.h"
#import "RegexKitLite.h"

@implementation IRI

- (IRI*) copy {
    return [[IRI alloc] initWithValue:_iriString relativeToIRI:_baseIRI];
}

- (IRI*) init {
    if (self = [super init]) {
        _iriString  = @"";
        _baseIRI    = nil;
        _components = @{};
        NSError* error;
        if (error) {
            NSLog(@"IRI initialization error: %@", error);
            return nil;
        }
    }
    return self;
}

- (IRI*) initWithComponents: (NSDictionary*) components {
    if (self = [self init]) {
        NSMutableString* iri = [NSMutableString string];
        if (components[@"scheme"]) {
            [iri appendString:components[@"scheme"]];
            [iri appendString:@":"];
        }
        
        if (components[@"authority"]) {
            [iri appendString:@"//"];
            NSDictionary* auth  = components[@"authority"];
            //  [ iuserinfo "@" ] ihost [ ":" port ]
            NSMutableString* authority = [NSMutableString string];
            if (auth[@"user"]) {
                [authority appendString:auth[@"user"]];
                [authority appendString:@"@"];
            }
            [authority appendString:auth[@"host"]];
            if (auth[@"port"]) {
                [authority appendString:@":"];
                [authority appendString:auth[@"port"]];
            }
            [iri appendString:authority];
        }
        
        if (!components[@"path"]) {
            NSLog(@"Cannot initialize an IRI with no path component.");
            return nil;
        }
        [iri appendString:components[@"path"]];
        
        if (components[@"query"]) {
            [iri appendString:@"?"];
            [iri appendString:components[@"query"]];
        }

        if (components[@"fragment"]) {
            [iri appendString:@"#"];
            [iri appendString:components[@"fragment"]];
        }
        
        _components = [components copy];
        _iriString  = [iri copy];
        _baseIRI    = nil;
    }
    return self;
}

- (IRI*) initWithValue: (NSString*) iri relativeToIRI: (IRI*) base {
    if (self = [self init]) {
//        NSLog(@"Initializing IRI <%@> relative to base %@", iri, base);
        _iriString  = [iri copy];
        _baseIRI    = base ? [base copy] : nil;
        NSError* error;
        [self parseWithError:&error];
//        NSLog(@"in-flight init components for %@: %@", iri, _components);
        if (error) {
            NSLog(@"IRI initialization error: %@", error);
            return nil;
        }
        
        if (base && !_components[@"scheme"]) {
            _iriString  = [self absoluteString];
        }
        
        if (error) {
            NSLog(@"IRI error: %@", error);
            return nil;
        }
//        NSLog(@"IRI <%@> components: %@", _iriString, _components);
//        NSLog(@"final init components for %@: %@", iri, _components);
    }
    return self;
}

- (NSDictionary*) components {
    return _components;
}

+ (NSString*) pathByMergingBase: (NSDictionary*) base withComponents: (NSDictionary*) components {
//    NSLog(@"==========> merging:\n%@\n%@", base, components);
    if (base[@"authority"] && [base[@"path"] length] == 0) {
        //        return a string consisting of "/" concatenated with the reference's path; otherwise,
//        NSLog(@"merging base with authority but empty path with: %@", components);
        return [NSString stringWithFormat:@"/%@", components[@"path"]];
    } else {
//        NSLog(@"merging base: %@ %@", base, components);
        NSString* basePath  = base[@"path"];
        NSMutableArray* pathParts  = [[basePath componentsSeparatedByString:@"/"] mutableCopy];
        [pathParts removeLastObject];
        [pathParts addObject:components[@"path"]];
        NSString* path  = [pathParts componentsJoinedByString:@"/"];
//        NSLog(@"---> merged path: %@", path);
        return path;
    }
}

+ (NSString*) pathByRemovingDotSegmentsFromPath: (NSString*) path {
    NSMutableString* input  = [path mutableCopy];
    NSMutableArray* output  = [NSMutableArray array];
    while ([input length]) {
        if ([input hasPrefix:@"../"]) {
            [input replaceCharactersInRange:NSMakeRange(0, 3) withString:@""];
        } else if ([input hasPrefix:@"./"]) {
            [input replaceCharactersInRange:NSMakeRange(0, 2) withString:@""];
        } else if ([input hasPrefix:@"/./"]) {
            [input replaceCharactersInRange:NSMakeRange(0, 3) withString:@"/"];
        } else if ([input hasPrefix:@"/."] && ([input length] == 2)) {
            [input replaceCharactersInRange:NSMakeRange(0, 2) withString:@"/"];
        } else if ([input hasPrefix:@"/../"]) {
            [input replaceCharactersInRange:NSMakeRange(0, 4) withString:@"/"];
            [output removeLastObject];
        } else if ([input hasPrefix:@"/.."] && ([input length] == 3)) {
            [input replaceCharactersInRange:NSMakeRange(0, 3) withString:@"/"];
            [output removeLastObject];
        } else if ([input isEqualToString:@"."]) {
            [input replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        } else if ([input isEqualToString:@".."]) {
            [input replaceCharactersInRange:NSMakeRange(0, 2) withString:@""];
        } else {
            BOOL leadingSlash       = [input hasPrefix:@"/"];
            if (leadingSlash) {
                [input replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            NSMutableArray* parts   = [[input componentsSeparatedByString:@"/"] mutableCopy];
            NSString* part          = [parts firstObject];
            [parts removeObjectAtIndex:0];
            if ([parts count]) {
                [parts insertObject:@"" atIndex:0];
            }
            input   = [[parts componentsJoinedByString:@"/"] mutableCopy];
            if (leadingSlash)
                part    = [NSString stringWithFormat:@"/%@", part];
            [output addObject:part];
        }
    }
    NSString* newPath   = [output componentsJoinedByString:@""];
//    NSLog(@"Removing dots:\n-> %@\n=> %@", path, newPath);
    return newPath;
}

- (NSString *)absoluteString {
    if (_baseIRI && !_components[@"scheme"]) {
        // Resolve IRI relative to the base IRI
//        NSLog(@"resolving IRI <%@> relative to the base IRI <%@>", _iriString, [_baseIRI absoluteString]);
        NSDictionary* components    = _components;
        NSDictionary* base          = [_baseIRI components];
//        NSLog(@"base components: %@", base);
//        NSLog(@"rel components: %@", components);
        NSMutableDictionary* target = [NSMutableDictionary dictionary];
        
        if (components[@"scheme"]) {
//            NSLog(@"have scheme");
            target[@"scheme"]       = components[@"scheme"];
            target[@"authority"]    = components[@"authority"];
            target[@"path"]         = components[@"path"];  // TODO: should be remove_dots(components[@"path"])
            target[@"query"]        = components[@"query"];
        } else {
//            NSLog(@"no scheme");
            if (components[@"authority"]) {
//                NSLog(@"have authority");
                target[@"authority"]    = components[@"authority"];
                target[@"path"]         = components[@"path"];  // TODO: should be remove_dots(components[@"path"])
                target[@"query"]        = components[@"query"];
            } else {
//                NSLog(@"no authority");
                if ([components[@"path"] isEqualToString:@""]) {
//                    NSLog(@"have path");
                    target[@"path"] = base[@"path"];
                    if (components[@"query"]) {
//                        NSLog(@"have query");
                        target[@"query"]        = components[@"query"];
                    } else {
//                        NSLog(@"no query");
                        if (base[@"query"]) {
//                            NSLog(@"setting query from base");
                            target[@"query"]        = base[@"query"];
                        }
                    }
                } else {
//                    NSLog(@"no path");
                    if ([components[@"path"] hasPrefix:@"/"]) {
//                        NSLog(@"path has prefix /");
                        target[@"path"]         = components[@"path"];  // TODO: should be remove_dots(components[@"path"])
                    } else {
//                        NSLog(@"path without prefix /");
                        target[@"path"] = [IRI pathByMergingBase:base withComponents:components];
                        target[@"path"] = [IRI pathByRemovingDotSegmentsFromPath: target[@"path"]];
                    }
                    if (components[@"query"]) {
//                        NSLog(@"setting query from resource");
                        target[@"query"]        = components[@"query"];
                    }
                }
                if (base[@"authority"]) {
//                    NSLog(@"setting authority from base");
                    target[@"authority"]        = base[@"authority"];
                }
            }
            if (base[@"scheme"]) {
//                NSLog(@"setting scheme from base");
                target[@"scheme"]   = base[@"scheme"];
            }
        }
        if (components[@"fragment"]) {
//            NSLog(@"setting fragment from resource");
            target[@"fragment"] = components[@"fragment"];
        }
        
        // TODO: re-combine the target components
        
//        NSLog(@"target components: %@", target);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
        [self initWithComponents:target];
#pragma clang diagnostic pop
    }
//    NSLog(@"====> %@", _iriString);
    return _iriString;
}

- (NSString *)scheme {
    return _components[@"scheme"];
}

- (NSString *)resourceSpecifier {
    NSString* scheme    = _components[@"scheme"];
    NSMutableString* iri    = [_iriString mutableCopy];
    [iri replaceCharactersInRange:NSMakeRange(0, [scheme length]) withString:@""];
    return iri;
}

- (NSString *)host {
    return _components[@"host"];
}

- (NSNumber *)port {
    NSString* string    = _components[@"host"];
    long long value     = atoll([string UTF8String]);
    NSNumber* port      = [NSNumber numberWithLongLong:value];
    return port;
}

- (NSString *)user {
    return _components[@"user"];
}

- (NSString *)password {
    // TODO: not defined for IRIs(?)
    return nil;
}

- (NSString *)path {
    return _components[@"path"];
}

- (NSString *)fragment {
    return _components[@"fragment"];
}

- (NSString *)parameterString {
    // TODO: not defined for IRIs(?)
    return nil;
}

- (NSString *)query {
    return _components[@"query"];
}

- (NSString *)relativePath { // The same as path if baseURL is nil
    return [self path];
}

#pragma mark -

//    IRI-reference  = IRI / irelative-ref
- (NSDictionary*) parseWithError:(NSError**) error {
    if (!_components || ![_components count]) {
        NSMutableString* iri        = [_iriString mutableCopy];
        
        NSDictionary* dict;
        NSRange range   = [iri rangeOfRegex:@"([A-Za-z][-A-Za-z0-9+.]*):"];
        if (range.location == 0) {
            // IRI begins with scheme ':'
            dict    = [self parse_IRI:iri asComponentsWithError:error];
        } else {
            dict    = [self parse_irelative_ref:iri asComponentsWithError:error];
        }
        
        if (!dict[@"path"]) {
            NSMutableDictionary* d  = [NSMutableDictionary dictionaryWithDictionary:dict];
            d[@"path"]  = @"";  // All IRIs have a path, even if it's empty
            dict        = [d copy];
        }
        
        if (*error)
            return nil;
        
        if ([iri length]) {
            *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"Unexpected content at end of IRI: %@", iri], @"components": dict}];
            return nil;
        }
        
        _components = dict;
    }
    return _components;
}

//IRI            = scheme ":" ihier-part [ "?" iquery ] [ "#" ifragment ]
- (NSDictionary*) parse_IRI: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSRange range   = [iri rangeOfRegex:@"([A-Za-z][-A-Za-z0-9+.]*):"];
    if (range.location == NSNotFound) {
        *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:3 userInfo:@{@"description": @"Scheme not found in IRI", @"iri": iri}];
        return nil;
    }
    NSMutableDictionary* dict   = [NSMutableDictionary dictionary];
    dict[@"scheme"] = [iri substringWithRange:NSMakeRange(0, range.length-1)];
    [iri replaceCharactersInRange:range withString:@""];
    
    NSDictionary* hierDict  = [self parse_ihier_part: iri asComponentsWithError:error];
    [dict addEntriesFromDictionary:hierDict];
    
    if ([iri hasPrefix:@"?"]) {
        [iri replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        NSDictionary* query = [self parse_iquery:iri asComponentsWithError:error];
        [dict addEntriesFromDictionary:query];
    }
    
    if ([iri hasPrefix:@"#"]) {
        [iri replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        NSDictionary* frag = [self parse_ifragment:iri asComponentsWithError:error];
        [dict addEntriesFromDictionary:frag];
    }
    
    return [dict copy];
}

//irelative-ref  = irelative-part [ "?" iquery ] [ "#" ifragment ]
- (NSDictionary*) parse_irelative_ref: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSMutableDictionary* dict  = [[self parse_irelative_part:iri asComponentsWithError:error] mutableCopy];
    
    if ([iri hasPrefix:@"?"]) {
        [iri replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        NSDictionary* query = [self parse_iquery:iri asComponentsWithError:error];
        [dict addEntriesFromDictionary:query];
    }
    
    if ([iri hasPrefix:@"#"]) {
        [iri replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        NSDictionary* frag = [self parse_ifragment:iri asComponentsWithError:error];
        [dict addEntriesFromDictionary:frag];
    }
    
    return [dict copy];
}

//ihier-part     = "//" iauthority ipath-abempty
//  / ipath-absolute
//  / ipath-rootless
//  / ipath-empty
- (NSDictionary*) parse_ihier_part: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ipchar_re = @"(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])";
    if ([iri hasPrefix:@"//"]) {
        [iri replaceCharactersInRange:NSMakeRange(0, 2) withString:@""];
        NSDictionary* auth  = [self parse_iauthority:iri asComponentsWithError:error];
        if (!auth) return nil;
        NSDictionary* path  = [self parse_ipath_abempty:iri asComponentsWithError:error];
        if (!path) return nil;
        NSMutableDictionary* dict  = [NSMutableDictionary dictionaryWithDictionary:auth];
        [dict addEntriesFromDictionary:path];
        return [dict copy];
    } else if ([iri hasPrefix:@"/"]) {
        return [self parse_ipath_absolute:iri asComponentsWithError:error];
    } else if ([iri rangeOfRegex:ipchar_re].location == 0) {
        return [self parse_ipath_rootless:iri asComponentsWithError:error];
    } else {
        // ipath-empty is 0-length; no-op
        return @{};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"unexpected content in parse_ihier_part: %@", iri]}];
    return nil;
}

//irelative-part = "//" iauthority ipath-abempty
// / ipath-absolute
// / ipath-noscheme
// / ipath-empty
- (NSDictionary*) parse_irelative_part: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ipchar_re = @"(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])";
    if ([iri hasPrefix:@"//"]) {
        [iri replaceCharactersInRange:NSMakeRange(0, 2) withString:@""];
        NSDictionary* auth  = [self parse_iauthority:iri asComponentsWithError:error];
        if (!auth) return nil;
        NSDictionary* path  = [self parse_ipath_abempty:iri asComponentsWithError:error];
        if (!path) return nil;
        NSMutableDictionary* dict  = [NSMutableDictionary dictionaryWithDictionary:auth];
        [dict addEntriesFromDictionary:path];
        return [dict copy];
    } else if ([iri hasPrefix:@"/"]) {
        return [self parse_ipath_absolute:iri asComponentsWithError:error];
    } else if ([iri rangeOfRegex:ipchar_re].location == 0) {
        return [self parse_ipath_noscheme:iri asComponentsWithError:error];
    } else {
        // ipath-empty is 0-length; no-op
        return @{};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"unexpected content in parse_irelative_part: %@", iri]}];
    return nil;
}

//iquery         = *( ipchar / iprivate / "/" / "?" )
- (NSDictionary*) parse_iquery: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* iquery_re = @"((?:[/?]|(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])|(?:(?:\\x{E000}-\\x{F8FF})|(?:\\x{F0000}-\\x{FFFFD})|(?:\\x{100000}-\\x{10FFFD})))*)";
    NSRange range   = [iri rangeOfRegex:iquery_re];
    if (range.location == 0) {
        NSString* query = [iri substringWithRange:NSMakeRange(0, range.length)];
        [iri replaceCharactersInRange:range withString:@""];
        return @{@"query": query};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"unexpected content in parse_iquery: %@", iri]}];
    return nil;
}

//ifragment      = *( ipchar / "/" / "?" )
- (NSDictionary*) parse_ifragment: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ifragment_re = @"((?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])|[/?])*)";
    NSRange range   = [iri rangeOfRegex:ifragment_re];
    if (range.location == 0) {
        NSString* query = [iri substringWithRange:NSMakeRange(0, range.length)];
        [iri replaceCharactersInRange:range withString:@""];
        return @{@"fragment": query};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"unexpected content in parse_ifragment: %@", iri]}];
    return nil;
}

//iauthority     = [ iuserinfo "@" ] ihost [ ":" port ]
//iuserinfo      = *( iunreserved / pct-encoded / sub-delims / ":" )
//ihost          = IP-literal / IPv4address / ireg-name
- (NSDictionary*) parse_iauthority: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* userinfo_re    = @"((?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|:)*)@";
    NSMutableDictionary* dict   = [NSMutableDictionary dictionary];
    NSRange range;
    
    NSMutableDictionary* authority  = [NSMutableDictionary dictionary];
    
    range   = [iri rangeOfRegex:userinfo_re];
    if (range.location == 0) {
        authority[@"user"] = [iri substringWithRange:NSMakeRange(0, range.length-1)];
        [iri replaceCharactersInRange:range withString:@""];
    }
    
    NSDictionary* host  = [self parse_ihost:iri asComponentsWithError:error];
    [authority addEntriesFromDictionary:host];
    
    range   = [iri rangeOfRegex:@":(\\d*)"];
    if (range.location == 0) {
        if (range.length > 1) {
            authority[@"port"] = [iri substringWithRange:NSMakeRange(1, range.length-1)];
        }
        [iri replaceCharactersInRange:range withString:@""];
    }
    
    dict[@"authority"]  = authority;
    return [dict copy];
}

//ipath-abempty  = *( "/" isegment )
- (NSDictionary*) parse_ipath_abempty: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ipath_re     = @"(?:(?:/(?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])+)*)*)";
    NSRange range    = [iri rangeOfRegex:ipath_re];
    if (range.location == 0) {
        NSString* path  = [iri substringWithRange:range];
        [iri replaceCharactersInRange:range withString:@""];
        return @{@"path": path};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"Unexpected content in parse_ipath_abempty: %@", iri]}];
    return nil;
}

//ipath-absolute = "/" [ isegment-nz *( "/" isegment ) ]
- (NSDictionary*) parse_ipath_absolute: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ipath_absolute_re = @"(/((?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])+)(/(?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])+))*)?)";
    NSRange range    = [iri rangeOfRegex:ipath_absolute_re];
    if (range.location == 0) {
        NSString* path  = [iri substringWithRange:range];
        [iri replaceCharactersInRange:range withString:@""];
        return @{@"path": path};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"Unexpected content in parse_ipath_absolute: %@", iri]}];
    return nil;
}

//ipath-rootless = isegment-nz *( "/" isegment )
- (NSDictionary*) parse_ipath_rootless: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ipath_absolute_re = @"((?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])+)(/(?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])+))*)";
    NSRange range    = [iri rangeOfRegex:ipath_absolute_re];
    if (range.location == 0) {
        NSString* path  = [iri substringWithRange:range];
        [iri replaceCharactersInRange:range withString:@""];
        return @{@"path": path};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"Unexpected content in parse_ipath_rootless: %@", iri]}];
    return nil;
}

//ihost          = IP-literal / IPv4address / ireg-name
- (NSDictionary*) parse_ihost: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ip_literal_re     = @"(?:\\[(?:(?:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:::[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:[A-Fa-f0-9]{1,4}::[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:(?:[A-Fa-f0-9]{1,4}:){,1}::[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:(?:[A-Fa-f0-9]{1,4}:){,2}::[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:(?:[A-Fa-f0-9]{1,4}:){,3}::[A-Fa-f0-9]{1,4}:(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:(?:[A-Fa-f0-9]{1,4}:){,4}::(?:[A-Fa-f0-9]{1,4}:[A-Fa-f0-9]{1,4}|(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))))|(?:(?:[A-Fa-f0-9]{1,4}:){,5}::[A-Fa-f0-9]{1,4})|(?:(?:[A-Fa-f0-9]{1,4}:){,6}::))|(?:v[A-Fa-f0-9]{1,}[.](?:(?:[-A-Za-z0-9._~])|(?:[!$&'()*+,;=])|:){1,}))\\])";
    NSString* IPv4address_re    = @"(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))[.](?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])))";
    NSString* ireg_name_re      = @"(?:((?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=]))*)";
    NSRange ip_lit_range    = [iri rangeOfRegex:ip_literal_re];
    NSRange ipv4_range      = [iri rangeOfRegex:IPv4address_re];
    NSRange name_range      = [iri rangeOfRegex:ireg_name_re];
    if (ip_lit_range.location == 0) {
        NSString* host  = [iri substringWithRange:ip_lit_range];
        [iri replaceCharactersInRange:ip_lit_range withString:@""];
        return @{@"host": host};
    } else if (ipv4_range.location == 0) {
        NSString* host  = [iri substringWithRange:ipv4_range];
        [iri replaceCharactersInRange:ipv4_range withString:@""];
        return @{@"host": host};
    } else if (name_range.location == 0) {
        NSString* host  = [iri substringWithRange:name_range];
        [iri replaceCharactersInRange:name_range withString:@""];
        return @{@"host": host};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"Unexpected content in parse_ihost: %@", iri]}];
    return nil;
}

//ipath-noscheme = isegment-nz-nc *( "/" isegment )
- (NSDictionary*) parse_ipath_noscheme: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
    NSString* ipath_re  = @"(?:(?:(?:@|(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=]))+)(/(?:(?:(?:[-A-Za-z0-9._~]|(?:[\\x{00A0}-\\x{D7FF}]|[\\x{F900}-\\x{FDCF}]|[\\x{FDF0}-\\x{FFEF}]|[\\x{10000}-\\x{1FFFD}]|[\\x{20000}-\\x{2FFFD}]|[\\x{30000}-\\x{3FFFD}]|[\\x{40000}-\\x{4FFFD}]|[\\x{50000}-\\x{5FFFD}]|[\\x{60000}-\\x{6FFFD}]|[\\x{70000}-\\x{7FFFD}]|[\\x{80000}-\\x{8FFFD}]|[\\x{90000}-\\x{9FFFD}]|[\\x{A0000}-\\x{AFFFD}]|[\\x{B0000}-\\x{BFFFD}]|[\\x{C0000}-\\x{CFFFD}]|[\\x{D0000}-\\x{DFFFD}]|[\\x{E1000}-\\x{EFFFD}]))|(?:%[A-Fa-f0-9]{2})|(?:[!$&'()*+,;=])|[:@])+))*)";
    NSRange range    = [iri rangeOfRegex:ipath_re];
    if (range.location == 0) {
        NSString* path  = [iri substringWithRange:range];
        [iri replaceCharactersInRange:range withString:@""];
        return @{@"path": path};
    }
    *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:2 userInfo:@{@"description": [NSString stringWithFormat:@"Unexpected content in parse_ipath_noscheme: %@", iri]}];
    return nil;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@>", _iriString];
}


/**


 
 - (NSDictionary*) parse_ifragment_ref: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
 *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:1 userInfo:@{@"description": [NSString stringWithFormat:@"parse_ipath_noscheme not implemented"]}];
 return nil;
 }

 - (NSDictionary*) parse_ifragment_ref: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
 *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:1 userInfo:@{@"description": [NSString stringWithFormat:@"parse_ipath_noscheme not implemented"]}];
 return nil;
 }

 - (NSDictionary*) parse_ifragment_ref: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
 *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:1 userInfo:@{@"description": [NSString stringWithFormat:@"parse_ipath_noscheme not implemented"]}];
 return nil;
 }

 - (NSDictionary*) parse_ifragment_ref: (NSMutableString*) iri asComponentsWithError: (NSError**) error {
 *error  = [NSError errorWithDomain:@"us.kasei.swbase.iri" code:1 userInfo:@{@"description": [NSString stringWithFormat:@"parse_ipath_noscheme not implemented"]}];
 return nil;
 }

 */

@end
