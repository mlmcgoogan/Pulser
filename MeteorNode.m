//
//  MeteorNode.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MeteorNode.h"
#import "GameLayer.h"
#import "Constants.h"
#import "CCQuadPhysicsParticleSystem.h"


@interface MeteorNode (PrivateMethods)

- (void)updatePositionStep:(ccTime)dt;

@end


@implementation MeteorNode

@synthesize particleSystem, start, unitVector, shape, pulseNode;

- (id)initWithStart:(CGPoint)startPos direction:(CGPoint)dirUnitVec space:(cpSpace *)space pulseNode:(PulseNode *)pNode {
	if ((self = [super init])) {
		
		self.pulseNode = pNode;
		
		sprite1 = [[CCSprite spriteWithFile:@"meteor.png"] retain];
		sprite1.color = ccc3(200, 40, 30);
		sprite1.blendFunc = (ccBlendFunc){GL_ONE, GL_ONE};
		sprite1.position = startPos;
		
		sprite2 = [[CCSprite spriteWithFile:@"meteor.png"] retain];
		sprite2.color = ccc3(150, 10, 10);
		sprite2.blendFunc = (ccBlendFunc){GL_ONE, GL_ONE};
		sprite2.position = startPos;
		
		[self addChild:sprite1];
		[self addChild:sprite2];
		
		cpBody *body = cpBodyNew(METEOR_MASS, INFINITY);
		body->p = startPos;
		
		shape = cpCircleShapeNew(body, METEOR_RADIUS, cpvzero);
		shape->u = 0.0;
		shape->e = 0.1;
		shape->collision_type = METEOR_COL_GROUP;
		shape->data = self;
		
		cpSpaceAddBody(space, body);
		cpSpaceAddShape(space, shape);
		
		CGPoint grav = ccpMult(dirUnitVec, 10.0);
		
		particleSystem = [[CCParticleMeteor alloc] initWithTotalParticles:200];
		particleSystem.startSize = 5;
		particleSystem.startSizeVar = 10;
		particleSystem.gravity = grav;
		particleSystem.position = startPos;
        particleSystem.life = 1.0;
        particleSystem.lifeVar = 0.5;
		particleSystem.posVar = ccp(10.0,10.0);
		particleSystem.startColor = ccc4FFromccc4B(ccc4(117,0,0,255));
		particleSystem.startColorVar = ccc4FFromccc4B(ccc4(0,100,0,0));
		particleSystem.endColor = ccc4FFromccc4B(ccc4(200,80,90,255));
		particleSystem.endColorVar = ccc4FFromccc4B(ccc4(150,40,40,0));
		start = startPos;
		unitVector = dirUnitVec;
		
		travelLife = 0.0;
		
		[self addChild:particleSystem];
		
	}
	
	return self;
}

- (void)dealloc {
	[particleSystem release];
	[sprite1 release];
	[sprite2 release];
	[pulseNode release];
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	
	[sprite1 runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/20 angle:2.0]]];
	[sprite2 runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/50 angle:-2.0]]];
	
    [[self.pulseNode.controller.bgLayer particleSystem] addRepulser:particleSystem];
	
	cpBody *body = shape->body;
	CGPoint delta = ccpMult(unitVector, 1800.0);
	cpBodyApplyImpulse(body, delta, cpvzero);
}

- (void)onExit {
    [[self.pulseNode.controller.bgLayer particleSystem] removeRepulser:particleSystem];
	
	[super onExit];
}

- (void)setPosition:(CGPoint)pos {
	[self.particleSystem setPosition:pos];
	sprite1.position = pos;
	sprite2.position = pos;
}

- (void)setRotation:(float)rot {
	
}

@end
