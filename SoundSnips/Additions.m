//
//  Additions.m
//  FlavorInfusion
//
//  Created by Sherwin Zadeh on 12/19/11.
//  Copyright (c) 2011 Artamata, Inc. All rights reserved.
//

#import "Additions.h"

@implementation NSDictionary (Additions)
- (id)notNullObjectForKey:(id)aKey {
	id obj = [self objectForKey:aKey];
	if ([obj isKindOfClass:[NSNull class]]) {
		return nil;
	}
	return obj;
}
@end
