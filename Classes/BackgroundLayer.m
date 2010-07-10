//
//  BackgroundLayer.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BackgroundLayer.h"


@implementation BackgroundLayer

- (id)init {
	if ((self = [super init])) {
		
		CGSize wins = [[CCDirector sharedDirector] winSize];
		
		particleSystem = [[CCPointParticleSystem alloc] initWithFile:@"BackgroundEmitter.plist"];
		particleSystem.position = ccp(wins.width/2,wins.height/2);
	}
	
	return self;
}

- (void)onEnter {
	[super onEnter];
	[self addChild:particleSystem];
}

- (void)onExit {
	[self removeChild:particleSystem cleanup:YES];
	[super onExit];
}

- (void)dealloc {
	[particleSystem release];
	[super dealloc];
}

@end
