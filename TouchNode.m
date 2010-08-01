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
		
		shells = [[NSMutableArray alloc] init];
		
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
		
		CCSpriteSheet *blendSheet = [controller blendSheet];
		CCSpriteSheet *noBlendSheet = [controller noBlendSheet];
		
		sprite = [[CCSprite alloc] initWithSpriteSheet:noBlendSheet rect:CGRectMake(0.0, 0.0, 130.0, 128.0)];
		//sprite.scaleX = 0.01;
		//sprite.scaleY = 0.01;
		[noBlendSheet addChild:sprite];
		sprite.position = pos;
		
		center = [[CCSprite alloc] initWithSpriteSheet:noBlendSheet rect:CGRectMake(130.0, 0.0, 130.0, 128.0)];
		[noBlendSheet addChild:center];
		center.position = pos;
		
		/*
		id s1,s2;
		s1 = [CCScaleTo actionWithDuration:1.0f scale:1.1];
		s2 = [CCScaleTo actionWithDuration:0.2f scale:1.0];
		[sprite runAction:[CCSequence actions:s1, s2, nil]];*/
		
		int outerShellCount = 0;
		int innerShellCount = 8;
		float speed = (float)(random() % 15 + 15);
		
		for (int i=0 ; i<outerShellCount ; i++) {
			speed = (float)(random() % 15 + 15);
			float shellSize = random() % 10 > 4 ? 390.0 : 260.0;
			float rotDir = random() & 10 > 4 ? 1.0 : -1.0;
			CCSprite *shellSprite = [CCSprite spriteWithSpriteSheet:blendSheet rect:CGRectMake(shellSize, 0.0, 130.0, 128.0)];
			float rot = (float)(random() % 360);
			shellSprite.position = pos;
			shellSprite.rotation = rot;
			[shellSprite runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/speed angle:rotDir]]];
			[shells addObject:shellSprite];
			[blendSheet addChild:shellSprite z:0];
		}
		speed = 10.0;
		float rotDir = 1.0;
		for (int i=0 ; i<innerShellCount ; i++) {
			speed += (float)(random() % 15 + 15);
			float shellSize;
			
			if (i < innerShellCount / 3) {
				shellSize = 780.0;
			}
			else if (i < innerShellCount / 3 * 2) {
				shellSize = 650.0;
			}
			else {
				shellSize = 520.0;
			}
			
			rotDir = -rotDir;
			CCSprite *shellSprite = [CCSprite spriteWithSpriteSheet:blendSheet rect:CGRectMake(shellSize, 0.0, 130.0, 128.0)];
			float rot = (float)(random() % 360);
			shellSprite.position = pos;
			shellSprite.rotation = rot;
			[shellSprite runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:1/speed angle:rotDir]]];
			[shells addObject:shellSprite];
			[blendSheet addChild:shellSprite];
		}
	}
}

- (void)dealloc {
	[controller release];
	[shells release];
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
		
		for (CCSprite *shellSprite in shells) {
			CGFloat r,g,b;
			r = 140.0 + (float)(random() % 80 - 30);
			g = 140.0 + (float)(random() % 80 - 30);
			b = 255.0;
			id<CCRGBAProtocol> stn = (id<CCRGBAProtocol>)shellSprite;
			[stn setColor:ccc3((GLubyte)r, (GLubyte)g, (GLubyte)b)];
		}
		
		id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)sprite;
		[tn setColor:ccc3((GLubyte)newComps[0], (GLubyte)newComps[1], (GLubyte)newComps[2])];
		tn = (id<CCRGBAProtocol>)center;
		[tn setColor:ccc3((GLubyte)newComps[0], (GLubyte)newComps[1], (GLubyte)newComps[2])];
		
		if (kamikazeModeActive) {
			for (CCSprite *shell in shells) {
				id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)shell;
				[tn setColor:ccc3((GLubyte)newComps[0], (GLubyte)newComps[1], (GLubyte)newComps[2])];
			}
		}
	}
}

#define PROXIMITY_THRESHOLD 400.0f
#define DEFAULT_COLOR ccc3(66,103,223)

- (void)tintNodeBasedOnMeteorProximity:(NSArray *)meteors {
	id<CCRGBAProtocol> tn = (id<CCRGBAProtocol>)center;
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
	[center setPosition:pos];
	
	for (CCSprite *spr in shells) {
		[spr setPosition:pos];
	}
	
	if (kamikazeModeActive) {
		kamikazeSystem.position = pos;
	}
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
	CGPoint pos = [self localTouchPoint:touch];
	
	CGPoint vect = ccpNormalize(ccpSub(pos, touchStart));
	CGFloat mag = fabsf(ccpDistance(pos, touchStart)) * 50.0;
	
	vect = ccpMult(vect, mag);
	
	cpBodyApplyImpulse(self.shape->body, vect, cpvzero);
}

#pragma mark -
#pragma mark Removal

- (void)prepForRemoval {
	CCSpriteSheet *blendSheet = [controller blendSheet];
	CCSpriteSheet *noBlendSheet = [controller noBlendSheet];
	
	[noBlendSheet removeChild:sprite cleanup:YES];
	[noBlendSheet removeChild:center cleanup:YES];
	for (CCSprite *spr in shells)
		[blendSheet removeChild:spr cleanup:YES];
	
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