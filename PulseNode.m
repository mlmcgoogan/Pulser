//
//  PulseNode.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PulseNode.h"
#import "MeteorNode.h"
#import "Constants.h"
#import "Player.h"
#import "TouchNode.h"

static void
dampingVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	damping = 0.95;
	cpBodyUpdateVelocity(body, gravity, damping, dt);
}

@interface PulseNode (PrivateMethods)

- (void)launchMeteorStep:(ccTime)dt;

@end


@implementation PulseNode

@synthesize particleSystem, meteors, player, controller;

- (id)initWithPosition:(CGPoint)pos space:(cpSpace *)space {
	if ((self = [super init])) {
		meteors = [[NSMutableArray alloc] init];
		currentDestination = CGPointZero;
		
		_space = space;
		
		cpBody *body = cpBodyNew(PULSENODE_MASS, INFINITY);
		body->p = pos;
		body->velocity_func = dampingVelocityFunc;
		
		shape = cpCircleShapeNew(body, PULSENODE_RADIUS, cpvzero);
		shape->u = 0.1;
		shape->e = 0.8;
		shape->collision_type = PULSENODE_COL_GROUP;
		shape->data	 = self;
		
		cpSpaceAddBody(space, body);
		cpSpaceAddShape(space, shape);
		
		
		pathBody = cpBodyNew(INFINITY, INFINITY);
		pathBody->p = ccpAdd(pos, ccp(100.0,0.0));
		
		joint = cpPinJointNew(pathBody, body, cpvzero, cpvzero);
		cpSpaceAddConstraint(space, joint);
		
		particleSystem = [[CCQuadParticleSystem alloc] initWithFile:@"pulseNode.plist"];
		particleSystem.position = pos;
		[self addChild:particleSystem];
		
	}
	
	return self;
}

- (void)dealloc {
	[particleSystem release];
	[meteors release];
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	
	[self schedule:@selector(launchMeteorStep:) interval:5.0f];
	[self schedule:@selector(updateStep:)];
}

- (void)onExit {
	[super onExit];
	
	[self unschedule:@selector(launchMeteorStep:)];
	[self unschedule:@selector(updateStep:)];
}

- (void)setPosition:(CGPoint)pos {
	self.particleSystem.position = pos;
}

- (void)setRotation:(float)rot {
	
}

#pragma mark -
#pragma mark Moving PulseNode

- (CGPoint)randomPoint {
	float x = (float)(random() % 824) + 100.0;
	float y = (float)(random() % 568) + 100.0;
	
	return ccp(x,y);
}

- (void)updateStep: (ccTime)dt {
	CGPoint newPos = pathBody->p;
	
	if (CGPointEqualToPoint(currentDestination, CGPointZero)) {
		currentDestination = [self randomPoint];
	}
	
	if (ccpDistance(currentDestination, pathBody->p) < 5.0) {
		currentDestination = [self randomPoint];
	}
	
	CGFloat distance = ccpDistance(currentDestination, pathBody->p);
	CGPoint delta = ccpSub(currentDestination, pathBody->p);
	
	newPos.x += delta.x / (distance / 0.8);
	newPos.y += delta.y / (distance / 0.8);
	
	pathBody->p = newPos;
}

#pragma mark -
#pragma mark Meteors

- (void)launchMeteorStep:(ccTime)dt {
	if ([[player touchNodes] count] > 0) {
		NSArray *touchNodes = [player touchNodes];
		int ind = random() % [touchNodes count];
		TouchNode *tNode = [touchNodes objectAtIndex:ind];
		
		CGPoint end = ccpSub(tNode.shape->body->p, self.particleSystem.position);
		end.x = end.x + (float)(random() % 40) - 20.0;
		end.y = end.y + (float)(random() % 40) - 20.0;
		
		end = ccpNormalize(end);
		MeteorNode *met = [[[MeteorNode alloc] initWithStart:self.particleSystem.position direction:end space:_space pulseNode:self] autorelease];
		[meteors addObject:met];
		[self addChild:met];
	}
}

- (void)removeMeteor:(MeteorNode *)meteor {
	[meteors removeObject:meteor];
	[self removeChild:meteor cleanup:YES];
}

#pragma mark -
#pragma mark Removing PulseNode

- (void)prepForRemoval {
	cpSpaceRemoveConstraint(_space, joint);
	cpConstraintFree(joint);
	
	cpSpaceRemoveBody(_space, pathBody);
	cpBodyFree(pathBody);
}

@end
