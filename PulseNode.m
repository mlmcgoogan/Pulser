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
#import "GameLayer.h"
#import "CCQuadPhysicsParticleSystem.h"

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
@synthesize type;

- (id)initWithPosition:(CGPoint)pos space:(cpSpace *)space type:(PulseNodeType)aType {
	if ((self = [self initWithPosition:pos space:space])) {
		type = aType;
		
		switch (type) {
			case kmMeteorPulseNodeType:
				[self initMeteorType];
				break;
			case kmGravityWellPulseNodeType:
				[self initGravityWellType];
				break;
			default:
				return nil;
		}
	}
	
	return self;
}

- (id)initWithPosition:(CGPoint)pos space:(cpSpace *)space {
	if ((self = [super init])) {
		currentDestination = CGPointZero;
		
		_space = space;
		type = kmMeteorPulseNodeType;
		
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
	}
	
	return self;
}

- (void)initMeteorType {
	CGPoint pos = shape->body->p;
	
	meteors = [[NSMutableArray alloc] init];
	
	ccColor3B color = ccc3(230, 30, 40);
	
	CCSpriteSheet *sheet = [CCSpriteSheet spriteSheetWithFile:@"meteorLauncher.png"];
	sheet.blendFunc = (ccBlendFunc){ GL_ONE, GL_ONE };
	outer = [[CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(0, 0, 106, 136)] retain];
	outer.position = pos;
	outer.color = ccc3(230, 30, 40);
	[sheet addChild:outer];
	middle = [[CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(124, 0, 94, 136)] retain];
	middle.position = pos;
	middle.color = ccc3(200, 0, 40);
	[sheet addChild:middle];
	inner = [[CCSprite spriteWithSpriteSheet:sheet rect:CGRectMake(240, 0, 84, 136)] retain];
	inner.position = pos;
	inner.color = ccc3(180, 0, 0);
	[sheet addChild:inner];
	
	[self addChild:sheet];
}

- (void)initGravityWellType {
	particleSystem = [[CCPointParticleSystem alloc] initWithFile:@"gravityWell.plist"];
	particleSystem.position = shape->body->p;
	
	[self addChild:particleSystem];
}

- (void)dealloc {
	if (type == kmGravityWellPulseNodeType) {
		[particleSystem release];
	}
	else if (type == kmMeteorPulseNodeType) {
		[outer release];
		[middle release];
		[inner release];
		[meteors release];
	}
	
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	
	if (type == kmMeteorPulseNodeType) {
		id rotate = [CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/40 angle:1.0]];
		id rotate2 = [CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/40 angle:1.0]];
		id revRotate = [CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/40 angle:-1.0]];
		
		[outer runAction:rotate2];
		[middle runAction:revRotate];
		[inner runAction:rotate];
		
		[self schedule:@selector(launchMeteorStep:) interval:5.0f];
	}
	else if (type == kmGravityWellPulseNodeType) {
		[[controller.bgLayer particleSystem] addAttractor:particleSystem];
	}
	
	
	[self schedule:@selector(updateStep:)];
}

- (void)onExit {
	[super onExit];
	
	if (type == kmMeteorPulseNodeType)
		[self unschedule:@selector(launchMeteorStep:)];
	else if (type == kmGravityWellPulseNodeType) {
		[[controller.bgLayer particleSystem] removeAttractor:particleSystem];
	}
	
	[self unschedule:@selector(updateStep:)];
}

- (void)setPosition:(CGPoint)pos {
	if (type == kmMeteorPulseNodeType) {
		outer.position = pos;
		middle.position = pos;
		inner.position = pos;
	}
	else if (type == kmGravityWellPulseNodeType) {
		particleSystem.position = pos;
	}
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
		
		CGPoint end = ccpSub(tNode.shape->body->p, outer.position);
		end.x = end.x + (float)(random() % 40) - 20.0;
		end.y = end.y + (float)(random() % 40) - 20.0;
		
		end = ccpNormalize(end);
		MeteorNode *met = [[[MeteorNode alloc] initWithStart:outer.position direction:end space:_space pulseNode:self] autorelease];
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
