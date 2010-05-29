//
//  Player.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Player.h"
#import "TouchNode.h"

@implementation Player

@synthesize color;

- (id)init {
	if ((self = [super init])) {
		touchNodes = [[NSMutableArray alloc] init];
		color = nil;
	}
	
	return self;
}

- (void)dealloc {
	[touchNodes release];
	[color release];
	[super dealloc];
}

#pragma mark -
#pragma mark Managing Node Color

- (void)setColor:(UIColor *)value {
	if (![value isEqual:color]) {
		for (TouchNode *node in touchNodes) {
			[node tintNode:value];
		}
		
		[color release];
		color = [value retain];
	}
}

#pragma mark -
#pragma mark Managing TouchNodes

- (void)addTouchNode:(TouchNode *)node {
	if (![touchNodes containsObject:node]) {
		node.player = self;
		if (color) {
			[node tintNode:color];
		}
		[touchNodes addObject:node];
	}
}

- (BOOL)removeTouchNode:(TouchNode *)node {
	if ([touchNodes containsObject:node]) {
		[touchNodes removeObject:node];
		return YES;
	}
	
	return NO;
}

- (NSArray *)touchNodes {
	return [NSArray arrayWithArray:touchNodes];
}

@end
