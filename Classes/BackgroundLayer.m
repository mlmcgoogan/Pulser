//
//  BackgroundLayer.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BackgroundLayer.h"


@implementation BackgroundLayer

@synthesize particleSystem;

- (id)initWithSpace:(cpSpace *)space {
	if ((self = [super init])) {
		_space = space;
		
		particleSystem = [[CCQuadPhysicsParticleSystem alloc] initWithTotalParticles:400 chipmunkSpace:space];
		particleSystem.position = ccp(0,0);
	}
	
	return self;
}

- (void)onEnter {
	[super onEnter];
	[CCTexture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGB565];
	CCSprite *spr = [CCSprite spriteWithFile:@"bg1.png"];
	spr.anchorPoint = ccp(0,0);
	
	CCRenderTexture *rTex = [CCRenderTexture renderTextureWithWidth:1024 height:768];
	rTex.position = ccp(512,384);
	rTex.anchorPoint = ccp(0,0);
	
	[rTex begin];
	[spr visit];
	[rTex end];
	
	[CCTexture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_Default];
	
	[self addChild:rTex];
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

- (void)update {
	[particleSystem postStep];
}

@end
