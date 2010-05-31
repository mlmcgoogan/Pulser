//
//  TouchNode.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TouchNode.h"
#import "GameLayer.h"
#import "MeteorNode.h"
#import "Constants.h"


#pragma mark -
#pragma mark Chipmunk

static void
dampingVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	damping = 0.99;
	cpBodyUpdateVelocity(body, gravity, damping, dt);
}

#pragma mark -



@interface TouchNode (PrivateMethods)

- (CGPoint)localTouchPoint:(UITouch *)touch;

@end

@implementation TouchNode

@synthesize sprite, particleSystem, player, shape;

+ (id)nodeWithPosition:(CGPoint)pos sheet:(CCSpriteSheet *)sheet space:(cpSpace *)space {
	return [[[self alloc] initWithSpritePosition:pos sheet:(CCSpriteSheet *)sheet space:space] autorelease];
}

- (id) init {
	if ((self = [super init])) {
		sprite = nil;
		player = nil;
	}
	
	return self;
}

- (id)initWithSpritePosition:(CGPoint)pos sheet:(CCSpriteSheet *)sheet space:(cpSpace *)space {
	if ((self = [self init])) {
		
		touchCurrent = CGPointZero;
		_space = space;
		
		cpBody *body = cpBodyNew(TOUCHNODE_MASS, cpMomentForCircle(TOUCHNODE_MASS, TOUCHNODE_RADIUS, TOUCHNODE_RADIUS, cpvzero));
		body->velocity_func = dampingVelocityFunc;
		body->p = pos;
		
		shape = cpCircleShapeNew(body, TOUCHNODE_RADIUS, cpvzero);
		shape->u = 0.2;
		shape->e = 0.2;
		shape->collision_type = TOUCHNODE_COL_GROUP;
		shape->data = self;
		
		cpSpaceAddBody(space, body);
		cpSpaceAddShape(space, shape);
		
		[self initSpriteWithPosition:pos sheet:sheet];
	}
	
	return self;
}

- (void)initSpriteWithPosition:(CGPoint)pos sheet:(CCSpriteSheet *)sheet {
	if (!sprite) {
		/*
		particleSystem = [[CCParticleSun alloc] initWithTotalParticles:10];
		particleSystem.position = pos;
		particleSystem.posVar = CGPointMake(50.0,50.0);
		particleSystem.startColor = ccc4FFromccc4B(ccc4(66, 103, 223, 255));
		[self addChild:particleSystem];
		 */
		
		sprite = [[CCSprite alloc] initWithSpriteSheet:sheet rect:CGRectMake(0.0, 0.0, 144.0, 144.0)];
		sprite.scaleX = 0.01;
		sprite.scaleY = 0.01;
		[sheet addChild:sprite];
		sprite.position = pos;
		
		id s1,s2,s3,s4,s5;
		s1 = [CCScaleTo actionWithDuration:1.0f scale:1.1];
		s2 = [CCScaleTo actionWithDuration:0.2f scale:1.0];
		[sprite runAction:[CCSequence actions:s1, s2, nil]];
	}
}

- (void)dealloc {
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (void)onExit {
	[super onExit];
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
}

#pragma mark -
#pragma mark HUD

- (void)draw {
	if (!CGPointEqualToPoint(touchCurrent, CGPointZero)) {
		ccDrawLine(self.shape->body->p, touchCurrent);
	}
}

#pragma mark -
#pragma mark Coloring

- (void)tintNode:(UIColor *)color {
	if (sprite) {
		int num;
		
		CGColorRef cgColor = [color CGColor];
		
		num = CGColorGetNumberOfComponents(cgColor);
		CGFloat *colorComponents;
		CGFloat newComps[num];
		colorComponents = CGColorGetComponents(cgColor);
		
		for (int i=0 ; i<num ; i++) {
			newComps[i] = colorComponents[i] * 255.0;
		}
		
		id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)sprite;
		[tn setColor:ccc3((GLubyte)newComps[0], (GLubyte)newComps[1], (GLubyte)newComps[2])];
	}
}

#define PROXIMITY_THRESHOLD 400.0f
#define DEFAULT_COLOR ccc3(66,103,223)

- (void)tintNodeBasedOnMeteorProximity:(NSArray *)meteors {
	id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)sprite;
	ccColor3B color = [tn color];
	
	MeteorNode *closest = nil;
	for (MeteorNode *node in meteors) {
		if (closest == nil) {
			closest = node;
			continue;
		}
		else if (fabsf(ccpDistance(node.particleSystem.position, sprite.position)) < fabsf(ccpDistance(closest.particleSystem.position, sprite.position))) {
			closest = node;
			continue;
		}
	}
	
	CGFloat distance = fabsf(ccpDistance(closest.particleSystem.position, sprite.position));
	
	if (distance > PROXIMITY_THRESHOLD) {
		[tn setColor:DEFAULT_COLOR];
		return;
	}
	
	CGFloat range = (PROXIMITY_THRESHOLD - 60.0);
	CGFloat normDist = distance - 60.0;
	normDist = normDist <= 0.0 ? 1.0 : normDist;
	
	CGFloat colorFactor = (range - normDist) / range;
	/*
	 *	We want a tendency toward red, red tones will increase with proximity,
	 *	green & blue will decrease
	 */
	color.r = (int)(255.0 * colorFactor);
	color.g = 103 - (int)(103.0*colorFactor);
	color.b = 223 - (int)(223.0*colorFactor);
	
	[tn setColor:color];
}

#pragma mark -
#pragma mark Chipmunk

- (void)setPosition:(CGPoint)pos {
	[self.sprite setPosition:pos];
}

- (void)setRotation:(float)rot {
	[self.sprite setRotation:rot];
}

#pragma mark -
#pragma mark Touch Handler

- (CGPoint)localTouchPoint:(UITouch *)touch {
	return [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	BOOL shouldCatch = NO;
	CGPoint pos = [self localTouchPoint:touch];
	
	CGFloat delta = fabsf(ccpDistance(pos, sprite.position));
	
	if (delta < TOUCHNODE_RADIUS) {
		touchStart = pos;
		shouldCatch = YES;
	}
	
	return shouldCatch;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint pos = [self localTouchPoint:touch];
	touchCurrent = pos;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	touchCurrent = CGPointZero;
	CGPoint pos = [self localTouchPoint:touch];
	
	CGPoint vect = ccpNormalize(ccpSub(pos, touchStart));
	CGFloat mag = fabsf(ccpDistance(pos, touchStart)) * 50.0;
	
	vect = ccpMult(vect, mag);
	
	cpBodyApplyImpulse(self.shape->body, vect, cpvzero);
}

@end