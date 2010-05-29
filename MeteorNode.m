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


@interface MeteorNode (PrivateMethods)

- (void)updatePositionStep:(ccTime)dt;

@end


@implementation MeteorNode

@synthesize particleSystem, start, unitVector, shape;

- (id)initWithStart:(CGPoint)startPos direction:(CGPoint)dirUnitVec space:(cpSpace *)space {
	if ((self = [super init])) {
		
		
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
		particleSystem.startColorVar = ccc4FFromccc4B(ccc4(120,60,80,0));
		start = startPos;
		unitVector = dirUnitVec;
		
		travelLife = 0.0;
		
		[self addChild:particleSystem];
		
	}
	
	return self;
}

- (void)dealloc {
	[particleSystem release];
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	
	cpBody *body = shape->body;
	CGPoint delta = ccpMult(unitVector, 1800.0);
	cpBodyApplyImpulse(body, delta, cpvzero);
}

- (void)onExit {
	[super onExit];
}

- (void)setPosition:(CGPoint)pos {
	[self.particleSystem setPosition:pos];
}

- (void)setRotation:(float)rot {
	
}

@end
