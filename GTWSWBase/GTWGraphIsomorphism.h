//
//  GTWGraphIsomorphism.h
//  GTWSWBase
//
//  Created by Gregory Williams on 9/23/13.
//  Copyright (c) 2013 Gregory Todd Williams. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTWGraphIsomorphism : NSObject

+ (BOOL) graphEnumerator: (NSEnumerator*) a isomorphicWith: (NSEnumerator*) b;

@end
