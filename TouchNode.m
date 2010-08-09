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

static cpFloat dampingValue = 1.0;

static void
dampingVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	damping = dampingValue;
	cpBodyUpdateVelocity(body, gravity, damping, dt);
}

#pragma mark -



@interface TouchNode (PrivateMethods)

- (CGPoint)localTouchPoint:(UITouch *)touch;

@end

@implementation TouchNode

@synthesize sprite, player, shape, controller;

+ (id)nodeWithPosition:(CGPoint)pos controller:(GameLayer *)gameController space:(cpSpace *)space {
	return [[[self alloc] initWithSpritePosition:pos controller:gameController space:space] autorelease];
}

- (id) init {
	if ((self = [super init])) {
		sprite = nil;
		player = nil;
	}
	
	return self;
}

- (id)initWithSpritePosition:(CGPoint)pos controller:(GameLayer *)gameController space:(cpSpace *)space {
	if ((self = [self init])) {
		
		dampingValue = 0.99;
		kamikazeSystem = nil;
		kamikazeModeActive = NO;
		kamikazeTimer = nil;
		controller = [gameController retain];
		
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
		
		[self initSpriteWithPosition:pos];
	}
	
	return self;
}
// 130.128
- (void)initSpriteWithPosition:(CGPoint)pos {
	if (!sprite) {
		
		CCSpriteSheet *sheet = [CCSpriteSheet spriteSheetWithFile:@"touchNode.png"];
		sheet.blendFunc = (ccBlendFunc){GL_ONE, GL_ONE};
		CGRect r = CGRectMake(0, 0, 100, 100);
		
		sprite = [[CCSprite spriteWithSpriteSheet:sheet rect:r] retain];
		[sprite runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/60 angle:-1.0]]];
		[sheet addChild:sprite];
		sprite.position = pos;
		
		NSMutableArray *arr = [NSMutableArray array];
		for (int i=0 ; i<2 ; i++) {
			CCSprite *spr = [CCSprite spriteWithSpriteSheet:sheet rect:r];
			spr.anchorPoint = i%2==0 ? ccp(0.55,0.55) : ccp(0.45,0.45);
			spr.position = pos;
			[spr runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/60 angle:(float)i*1.5]]];
			[sheet addChild:spr];
			[arr addObject:spr];
		}
		
		sprites = [[NSArray alloc] initWithArray:arr];
		
		[self addChild:sheet];
		
	}
}

- (void)dealloc {
	[sprites release];
	[sprite release];
	[controller release];
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
		
		ccColor3B color = ccc3((GLubyte)newComps[0], (GLubyte)newComps[1], (GLubyte)newComps[2]);
		
		id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)sprite;
		[tn setColor:color];
		
		for (CCSprite *spr in sprites) {
			id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)spr;
			[tn setColor:color];
		}
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
	
	for (CCSprite *spr in sprites) {
		tn = (id<CCRGBAProtocol>)spr;
		[tn setColor:color];
	}
}

#pragma mark -
#pragma mark Chipmunk

- (void)setPosition:(CGPoint)pos {
	[self.sprite setPosition:pos];
	
	for (CCSprite *spr in sprites)
		[spr setPosition:pos];
	
	if (kamikazeModeActive) {
		kamikazeSystem.position = pos;
	}
}

- (void)setRotation:(float)rot {
	
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
		
		if (!kamikazeModeActive) {
			kamikazeTimer = [NSTimer timerWithTimeInterval:2.5 target:self selector:@selector(activateKamikaze) userInfo:nil repeats:NO];
			[[NSRunLoop mainRunLoop] addTimer:kamikazeTimer forMode:NSDefaultRunLoopMode];
		}
	}
	
	return shouldCatch;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint pos = [self localTouchPoint:touch];
	touchCurrent = pos;
	
	if (fabsf(ccpDistance(touchCurrent, touchStart)) > 10.0 && kamikazeTimer != nil) {
		[kamikazeTimer invalidate];
		kamikazeTimer = nil;
	}
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	if (kamikazeTimer != nil) {
		[kamikazeTimer invalidate];
		kamikazeTimer = nil;
	}
	
	touchCurrent = CGPointZero;
	
	if (kamikazeModeActive) {
		CGPoint pos = [self localTouchPoint:touch];
		
		CGPoint vect = ccpNormalize(ccpSub(pos, touchStart));
		CGFloat mag = fabsf(ccpDistance(pos, touchStart)) * 50.0;
		
		vect = ccpMult(vect, mag);
		
		cpBodyApplyImpulse(self.shape->body, vect, cpvzero);
	}
}

#pragma mark -
#pragma mark Removal

- (void)prepForRemoval {
	
	if (kamikazeModeActive)
		[self deactivateKamikaze];
}

#pragma mark -
#pragma mark Kamikaze Mode

- (void)activateKamikaze {
	self.isTouchEnabled = NO;
	
	kamikazeTimer = nil;
	
	dampingValue = 1.0;
	shape->collision_type = KAMIKAZE_COL_GROUP;
	
	kamikazeSystem = [[CCPointParticleSystem alloc] initWithFile:@"Kamikaze.plist"];
	kamikazeSystem.position = sprite.position;
	
	[self tintNode:[UIColor redColor]];
	[controller addChild:kamikazeSystem z:0];
	
	kamikazeModeActive = YES;
}

- (void)deactivateKamikaze {
	self.isTouchEnabled = YES;
	
	dampingValue = 0.99;
	
	[controller removeChild:kamikazeSystem cleanup:YES];
	[kamikazeSystem release];
	kamikazeSystem = nil;
}

@end