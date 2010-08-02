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
		
		particleSystem = [[CCParticleMeteor alloc] initWithTotalParticles:110];
		particleSystem.startSize = 64;
		particleSystem.gravity = grav;
		particleSystem.position = startPos;
		particleSystem.startColor = ccc4FFromccc4B(ccc4(0,0,117,255));
		particleSystem.startColorVar = ccc4FFromccc4B(ccc4(158,0,0,0));
		particleSystem.endColor = ccc4FFromccc4B(ccc4(97,148,255,255));
		particleSystem.endColorVar = ccc4FFromccc4B(ccc4(255,0,178,0));
		start = startPos;
		unitVector = dirUnitVec;
		
		travelLife = 0.0;
		
		[self addChild:particleSystem];
		
	}
	
	return self;
}

- (void)dealloc {
	[particleSystem release];
	[pulseNode release];
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	
	//[[self.pulseNode.controller.bgLayer particleSystem] addEnemy:particleSystem];
    [[self.pulseNode.controller.bgLayer particleSystem] addRepulser:particleSystem];
	
	cpBody *body = shape->body;
	CGPoint delta = ccpMult(unitVector, 1800.0);
	cpBodyApplyImpulse(body, delta, cpvzero);
}

- (void)onExit {
	
	//[[self.pulseNode.controller.bgLayer particleSystem] removeEnemy:particleSystem];
    [[self.pulseNode.controller.bgLayer particleSystem] removeRepulser:particleSystem];
	[super onExit];
}

- (void)setPosition:(CGPoint)pos {
	[self.particleSystem setPosition:pos];
}

- (void)setRotation:(float)rot {
	
}

@end
