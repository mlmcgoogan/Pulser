//
//  GameScene.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameScene.h"
#import "GameLayer.h"

@implementation GameScene

- (id)init {
	if ((self = [super init])) {
		gameLayer = [[GameLayer alloc] init];
		[self addChild:gameLayer];
	}
	
	return self;
}

- (void)dealloc {
	[gameLayer release];
	[super dealloc];
}

@end
