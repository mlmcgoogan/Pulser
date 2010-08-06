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
		
		particleSystem = [[CCQuadPhysicsParticleSystem alloc] initWithTotalParticles:800];
		particleSystem.position = ccp(0,0);
	}
	
	return self;
}

- (void)onEnter {
	[super onEnter];
    
    
	//[CCTexture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGB565];
	CCSpriteSheet *sheet = [CCSpriteSheet spriteSheetWithFile:@"bg1.png"];
	[self addChild:sheet];
	
	CCSprite *bg1 = [CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(0, 0, 512, 384)];
	bg1.anchorPoint = CGPointZero;
	bg1.position = ccp(0,384.0);
	[sheet addChild:bg1];
	
	CCSprite *bg2 = [CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(512, 0, 512, 384)];
	bg2.anchorPoint = CGPointZero;
	bg2.position = ccp(512.0,384.0);
	[sheet addChild:bg2];
	
	CCSprite *bg3 = [CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(0, 384, 512, 384)];
	bg3.anchorPoint = CGPointZero;
	bg3.position = CGPointZero;
	[sheet addChild:bg3];
	
	CCSprite *bg4 = [CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(512, 384, 512, 384)];
	bg4.anchorPoint = CGPointZero;
	bg4.position = ccp(512.0,0);
	[sheet addChild:bg4];
     
    
    CGSize wins = [[CCDirector sharedDirector] winSize];
    
    CCSprite *scoreHUD = [CCSprite spriteWithFile:@"hud_score.png"];
    scoreHUD.scale = 0.8;
    scoreHUD.opacity = 100;
    scoreHUD.position = ccp(wins.width/2.0,wins.height-10.0);
    [self addChild:scoreHUD];
    
	[self addChild:particleSystem];
	[particleSystem startPhysics];
}

- (void)onExit {
	[particleSystem stopPhysics];
	[self removeChild:particleSystem cleanup:YES];
	[super onExit];
}

- (void)dealloc {
	[particleSystem release];
	[super dealloc];
}

- (void)update {
	[particleSystem updateQuad];
}

@end
