//
//  GameLayer
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "TouchNode.h"
#import "Player.h"
#import "PulseNode.h"
#import "MeteorNode.h"
#import "Constants.h"
#import "SpriteAutoRemoval.h"
#import "BackgroundLayer.h"
#import "CCQuadPhysicsParticleSystem.h"

#define SCORELABEL_PADDING 24.0

#pragma mark -
#pragma mark Chipmunk Callbacks

// Declarations
static void postStepMeteorRemoval(cpSpace *space, cpShape *shape, void *unused);
static void postStepTouchNodeRemoval(cpSpace *space, cpShape *shape, void *unused);
static void postStepPulseNodeRemoval(cpSpace *space, cpShape *shape, void *unused);

// Updating sprites
static void
eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	
	// Particles
	if (shape->collision_type == PARTICLE_COL_GROUP) {
        ccQuadPhysicsParticle *particle = shape->data;
		
		cpVect p = shape->body->p;
		
		GameLayer *gLayer = (GameLayer *)unused;
		CGPoint center = [[[gLayer.pulseNodes objectAtIndex:0] particleSystem] position];
		
		if (p.x > 1014.0 || p.x < 10.0 || p.y > 758.0 || p.y < 10.0)
			shape->body->p = cpv(1024.0 * CCRANDOM_0_1(), 768.0 * CCRANDOM_0_1());
		else if (p.x > center.x-10.0 && p.x < center.x+10.0 && p.y > center.y-10.0 && p.y < center.y+10.0)
			shape->body->p = cpv(1024.0 * CCRANDOM_0_1(), 768.0 * CCRANDOM_0_1());
		

		
		particle->position = shape->body->p;
	}
	
	// All other ccnode objects
	else {
		id node = shape->data;
		if( node ) {
			cpBody *body = shape->body;
			
			[node setPosition: body->p];
			[node setRotation: (float) CC_RADIANS_TO_DEGREES( -body->a )];
			
			if (unused != NULL && [node respondsToSelector:@selector(tintNodeBasedOnMeteorProximity:)]) {
				GameLayer *gLayer = (GameLayer *)unused;
				NSArray *meteors = [gLayer allMeteors];
				
				[node tintNodeBasedOnMeteorProximity:meteors];
			}
		}
	}
}

#pragma mark Meteor Removal

static int
meteorRemovalBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	cpShape *sensor, *meteor;
	cpArbiterGetShapes(arb, &sensor, &meteor);
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepMeteorRemoval, meteor, unused);
	
	return 0;
}

static void
postStepMeteorRemoval(cpSpace *space, cpShape *shape, void *unused)
{
	MeteorNode *mNode = (MeteorNode *)shape->data;
	PulseNode *pNode = mNode.pulseNode;
	[pNode removeMeteor:mNode];
	
	cpSpaceRemoveBody(space, shape->body);
	cpBodyFree(shape->body);
	
	cpSpaceRemoveShape(space, shape);
	cpShapeFree(shape);
}

#pragma mark Particle Collisions

static int
particleTouchCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	return 0;
}

static int
particleParticleCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	return 0;
}

static int
particleMeteorCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	return 0;
}

static int
particlePulseCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	return 0;
}

#pragma mark Ignore Meteor-Boundary Collisions

static int
meteorBoundaryIgnoreBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	return 0;
}

#pragma mark Meteor-TouchNode Collision

static int
meteorTouchCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	cpShape *meteor, *touchNode;
	cpArbiterGetShapes(arb, &meteor, &touchNode);
	
	GameLayer *gLayer = (GameLayer *)unused;
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, touchNode, NULL);
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepMeteorRemoval, meteor, NULL);
	
	[gLayer addCollisionAtPosition:cpArbiterGetPoint(arb, 0)];
	
	return 1;
}

static void
postStepTouchNodeRemoval(cpSpace *space, cpShape *shape, void *unused)
{
	TouchNode *tNode = (TouchNode *)shape->data;
	GameLayer *gLayer = tNode.controller;
	
	[tNode prepForRemoval];
	[gLayer removeChild:tNode cleanup:YES];
	[gLayer.player removeTouchNode:tNode];
	
	cpSpaceRemoveBody(space, shape->body);
	cpBodyFree(shape->body);
	
	cpSpaceRemoveShape(space, shape);
	cpShapeFree(shape);
}

#pragma mark Kamikaze Collisions

static int
kamikazeParticleCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	return 0;
}

static int
kamikazeTouchCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	cpShape *kamikaze, *touch;
	cpArbiterGetShapes(arb, &kamikaze, &touch);
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, kamikaze, NULL);
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, touch, NULL);
	
	TouchNode *tNode = (TouchNode *)kamikaze->data;
	[tNode.controller addCollisionAtPosition:cpArbiterGetPoint(arb, 0)];
	
	return 1;
}

static int
kamikazeMeteorCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	cpShape *kamikaze, *meteor;
	cpArbiterGetShapes(arb, &kamikaze, &meteor);
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, kamikaze, NULL);
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepMeteorRemoval, meteor, NULL);
	
	TouchNode *tNode = (TouchNode *)kamikaze->data;
	[tNode.controller addCollisionAtPosition:cpArbiterGetPoint(arb, 0)];
	
	return 1;
}

static int
kamikazeBoundaryCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	cpShape *kamikaze, *other;
	cpArbiterGetShapes(arb, &kamikaze, &other);
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, kamikaze, NULL);
	
	TouchNode *tNode = (TouchNode *)kamikaze->data;
	[tNode.controller addCollisionAtPosition:cpArbiterGetPoint(arb, 0)];
	
	return 1;
}

static int
kamikazePulseCollisionBegin(cpArbiter *arb, cpSpace *space, void *unused)
{
	cpShape *kamikaze, *pulse;
	cpArbiterGetShapes(arb, &kamikaze, &pulse);
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, kamikaze, NULL);
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepPulseNodeRemoval, pulse, NULL);
	
	TouchNode *tNode = (TouchNode *)kamikaze->data;
	[tNode.controller addCollisionAtPosition:cpArbiterGetPoint(arb, 0)];
	
	return 1;
}

static void
postStepPulseNodeRemoval(cpSpace *space, cpShape *shape, void *unused)
{
	PulseNode *pNode = (PulseNode *)shape->data;
	GameLayer *gLayer = pNode.controller;
	
	[gLayer removeChild:pNode cleanup:YES];
	
	cpSpaceRemoveBody(space, shape->body);
	cpBodyFree(shape->body);
	
	cpSpaceRemoveShape(space, shape);
	cpShapeFree(shape);
}

#pragma mark -
#pragma mark 


@implementation GameLayer

@synthesize pulseNodes, player, blendSheet, noBlendSheet, bgLayer;

- (id)init {
	if ((self = [super init])) {
		
		srandom(time(NULL));
		self.isTouchEnabled = YES;
		gameRuntime = 0;
		
		pulseNodes = [[NSMutableArray alloc] init];
		
		CGSize wins = [[CCDirector sharedDirector] winSize];
		
		/*****
		 ** CHIPMUNK INIT
		 *****/
		
		cpInitChipmunk();
		space = cpSpaceNew();
		space->gravity = cpvzero;
		
		cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
		
		/**
		 * BOUNDARIES
		 **/
		
		cpShape *boundary = cpSegmentShapeNew(staticBody, cpv(0.0,0.0), cpv(wins.width,0.0), 1.0);
		boundary->u = 0.2;
		boundary->e = 0.8;
		boundary->collision_type = BOUNDARY_COL_GROUP;
		
		cpSpaceAddStaticShape(space, boundary);
		
		boundary = cpSegmentShapeNew(staticBody, cpv(wins.width,0.0), cpv(wins.width,wins.height), 1.0);
		boundary->u = 0.2;
		boundary->e = 0.8;
		boundary->collision_type = BOUNDARY_COL_GROUP;
		
		cpSpaceAddStaticShape(space, boundary);
		
		boundary = cpSegmentShapeNew(staticBody, cpv(0.0,wins.height), cpv(wins.width,wins.height), 1.0);
		boundary->u = 0.2;
		boundary->e = 0.8;
		boundary->collision_type = BOUNDARY_COL_GROUP;
		
		cpSpaceAddStaticShape(space, boundary);
		
		boundary = cpSegmentShapeNew(staticBody, cpv(0.0,wins.height), cpv(0.0,0.0), 1.0);
		boundary->u = 0.2;
		boundary->e = 0.8;
		boundary->collision_type = BOUNDARY_COL_GROUP;
		
		cpSpaceAddStaticShape(space, boundary);
		
		/**
		 * OUT OF BOUNDS SENSORS (for removal)
		 **/
		
		cpVect leftSensorVerts[] = {
			cpv(-200.0, -200.0),
			cpv(-200.0, wins.height+200.0),
			cpv(-100.0, wins.height+200.0),
			cpv(-100.0, -200.0)
		};
		
		cpVect bottomSensorVerts[] = {
			cpv(-100.0, -200.0),
			cpv(-100.0, -100.0),
			cpv(wins.width+100.0, -100.0),
			cpv(wins.width+100.0, -200.0)
		};
		
		cpVect rightSensorVerts[] = {
			cpv(wins.width+200.0, -200.0),
			cpv(wins.width+100.0, -200.0),
			cpv(wins.width+100.0, wins.height+200.0),
			cpv(wins.width+200.0, wins.height+200.0)
		};
		
		cpVect topSensorVerts[] = {
			cpv(-100.0, wins.height+100.0),
			cpv(-100.0, wins.height+200.0),
			cpv(wins.width+100.0, wins.height+200.0),
			cpv(wins.width+100.0, wins.height+100.0)
		};
		
		cpShape *sensor = cpPolyShapeNew(staticBody, 4, leftSensorVerts, cpvzero);
		sensor->sensor = YES;
		sensor->collision_type = REMOVAL_SENSOR_COL_GROUP;
		cpSpaceAddShape(space, sensor);
		
		sensor = cpPolyShapeNew(staticBody, 4, bottomSensorVerts, cpvzero);
		sensor->sensor = YES;
		sensor->collision_type = REMOVAL_SENSOR_COL_GROUP;
		cpSpaceAddShape(space, sensor);
		
		sensor = cpPolyShapeNew(staticBody, 4, rightSensorVerts, cpvzero);
		sensor->sensor = YES;
		sensor->collision_type = REMOVAL_SENSOR_COL_GROUP;
		cpSpaceAddShape(space, sensor);
		
		sensor = cpPolyShapeNew(staticBody, 4, topSensorVerts, cpvzero);
		sensor->sensor = YES;
		sensor->collision_type = REMOVAL_SENSOR_COL_GROUP;
		cpSpaceAddShape(space, sensor);
		
		
		/*****
		 ** GAME ASSETS INIT
		 *****/
		
		bgLayer = [[BackgroundLayer alloc] initWithSpace:space];
		[self addChild:bgLayer z:0];
		
		noBlendSheet = [[CCSpriteSheet alloc] initWithFile:@"NoBlendSheet.png" capacity:20];
		[self addChild:noBlendSheet];
		
		blendSheet = [[CCSpriteSheet alloc] initWithFile:@"BlendSheet.png" capacity:40];
		blendSheet.blendFunc = (ccBlendFunc){ GL_ONE, GL_ONE };
		[self addChild:blendSheet];
		
		player = [[Player alloc] init];
		[player setColor:[UIColor colorWithRed:0.259 green:0.404 blue:0.875 alpha:1.0]];
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		PulseNode *pulseNode = [[PulseNode alloc] initWithPosition:CGPointMake(85.0, (s.height / 2.0)) space:space type:kmMeteorPulseNodeType];
		pulseNode.player = player;
		pulseNode.controller = self;
		[pulseNodes addObject:pulseNode];
		
		
		for (int i=0 ; i<1 ; i++) {
			CGFloat x = (float)(random() % 700) + 200.0;
			CGFloat y = (float)(random() % 500) + 100.0;
			TouchNode *node = [TouchNode nodeWithPosition:ccp(x,y) controller:self space:space];
			[self addChild:node];
			[player addTouchNode:node];
		}
		
		scoreLabel = [CCLabel labelWithString:@"Score: 000000" fontName:@"Helvetica" fontSize:24.0];
		scoreLabel.position = ccp(wins.width / 2.0, wins.height - SCORELABEL_PADDING);
		[self addChild:scoreLabel];
		
		/**
		 * Collision Callbacks
		 **/
		
		// Setup meteors for removal on collision with sensors
		cpSpaceAddCollisionHandler(space, REMOVAL_SENSOR_COL_GROUP, METEOR_COL_GROUP, meteorRemovalBegin, NULL, NULL, NULL, pulseNodes);
		cpSpaceAddCollisionHandler(space, BOUNDARY_COL_GROUP, METEOR_COL_GROUP, meteorBoundaryIgnoreBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, METEOR_COL_GROUP, TOUCHNODE_COL_GROUP, meteorTouchCollisionBegin, NULL, NULL, NULL, self);
		cpSpaceAddCollisionHandler(space, KAMIKAZE_COL_GROUP, TOUCHNODE_COL_GROUP, kamikazeTouchCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, KAMIKAZE_COL_GROUP, METEOR_COL_GROUP, kamikazeMeteorCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, KAMIKAZE_COL_GROUP, BOUNDARY_COL_GROUP, kamikazeBoundaryCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, KAMIKAZE_COL_GROUP, PULSENODE_COL_GROUP, kamikazePulseCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, KAMIKAZE_COL_GROUP, PARTICLE_COL_GROUP, kamikazeParticleCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, PARTICLE_COL_GROUP, TOUCHNODE_COL_GROUP, particleTouchCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, PARTICLE_COL_GROUP, PARTICLE_COL_GROUP, particleParticleCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, PARTICLE_COL_GROUP, METEOR_COL_GROUP, particleMeteorCollisionBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, PARTICLE_COL_GROUP, PULSENODE_COL_GROUP, particlePulseCollisionBegin, NULL, NULL, NULL, NULL);
		
		[self addChild:pulseNode];
	}
	
	return self;
}

- (void)dealloc {
	[bgLayer release];
	[blendSheet release];
	[noBlendSheet release];
	[player release];
	[pulseNodes release];
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	
	// Used to auto rotate interface based on orientation
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	
	[self schedule:@selector(mainStep:)];
	[self schedule:@selector(addTouchNodeStep:) interval:10.0];
	[self schedule:@selector(scoreStep:) interval:1.0/5.0];
	[self schedule:@selector(gameStep:) interval:30.0];
}

- (void)onExit {
	
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self unschedule:@selector(mainStep:)];
	[self unschedule:@selector(addTouchNodeStep:)];
	[super onExit];
}

#pragma mark -
#pragma mark Timers

- (void)mainStep:(ccTime) dt {
	int steps = 2;
	CGFloat delta = dt/(CGFloat)steps;
	
	for (int i=0 ; i<steps ; i++) {
		cpSpaceStep(space, delta);
	}
	
	cpSpaceHashEach(space->activeShapes, &eachShape, self);
	cpSpaceHashEach(space->staticShapes, &eachShape, NULL);
	
	[bgLayer update];
}

- (void)scoreStep:(ccTime)dt {
	score++;
	[scoreLabel setString:[NSString stringWithFormat:@"Score: %06d", score]];
}

- (void)gameStep:(ccTime) dt {
	if ([pulseNodes count] < 2) {
		
	}
}

#pragma mark -
#pragma mark Displaying a collision

- (void)addCollisionAtPosition:(CGPoint)pos {
	CCParticleSystem *pSys = [[[CCParticleExplosion alloc] initWithTotalParticles:200] autorelease];
	pSys.position = pos;
	pSys.gravity = CGPointZero;
	pSys.life = 1;
	pSys.lifeVar = 1;
	pSys.startColor = ccc4FFromccc4B(ccc4(51,102,179,255));
	pSys.startColorVar = ccc4FFromccc4B(ccc4(10,10,50,0));
	pSys.endColor = ccc4FFromccc4B(ccc4(0,0,0,255));
	pSys.blendAdditive = YES;
	[self addChild:pSys];
}

#pragma mark -
#pragma mark Adding TouchNodes

- (void)addTouchNodeStep:(ccTime)dt {
	int count = [[player touchNodes] count];
	
	if (count <= 3)
		[self addTouchNode];
}

- (void)addTouchNode {
	CGFloat x = (float)(random() % 700) + 200.0;
	CGFloat y = (float)(random() % 500) + 100.0;
	TouchNode *node = [TouchNode nodeWithPosition:ccp(x,y) controller:self space:space];
	[self addChild:node];
	[player addTouchNode:node];
}

#pragma mark -
#pragma mark Handling touches

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in [touches allObjects]) {
		CGPoint pos = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
		[self displayTap:pos];
		[self applyNavigationPulse:pos];
	}
}

- (void)displayTap:(CGPoint)pos {
	CCSprite *sprite = [CCSprite spriteWithFile:@"tapCircle.png"];
	sprite.position = pos;
	sprite.scale = 0.1;
	
	[self addChild:sprite];
	[sprite runAction:[CCSequence actions:[CCScaleTo actionWithDuration:0.1 scale:1.0], [CCCallFunc actionWithTarget:sprite selector:@selector(removeFromParent)], nil]];
}

#pragma mark -
#pragma mark Navigation

- (void)applyNavigationPulse:(CGPoint)pos {
	for (TouchNode *node in [player touchNodes]) {
		CGPoint nodePos = node.shape->body->p;
		
		CGPoint delta = ccpSub(nodePos, pos);
		CGPoint unitVec = ccpNormalize(delta);
		CGFloat distance = fabsf(ccpDistance(nodePos, pos));
		CGPoint forceVec = ccpMult(unitVec, (7.0/distance * 100000.0));
		
		cpBodyApplyImpulse(node.shape->body, forceVec, cpvzero);
	}
}

#pragma mark -
#pragma mark Game Assets

- (NSArray *)allMeteors {
	NSMutableArray *arr = [NSMutableArray array];
	for (PulseNode *pNode in pulseNodes) {
		[arr addObjectsFromArray:pNode.meteors];
	}
	
	return (NSArray *)arr;
}

#pragma mark -
#pragma mark Orientation changes

- (void)orientationDidChange:(NSNotification *)notification {
	UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
	switch (orient) {
		case UIDeviceOrientationPortrait:			[self rotateInterfacePortrait];					break;
		case UIDeviceOrientationPortraitUpsideDown:	[self rotateInterfacePortraitUpsideDown];		break;
		case UIDeviceOrientationLandscapeLeft:		[self rotateInterfaceLandscapeLeft];			break;
		case UIDeviceOrientationLandscapeRight:		[self rotateInterfaceLandscapeRight];			break;
		default:																					break;
	}
}

- (void)rotateInterfacePortrait {
	CGSize wins = [[CCDirector sharedDirector] winSize]; 
	scoreLabel.position = CGPointMake(wins.width - SCORELABEL_PADDING, wins.height / 2.0);
	scoreLabel.rotation = 90.0;
}

- (void)rotateInterfacePortraitUpsideDown {
	CGSize wins = [[CCDirector sharedDirector] winSize]; 
	scoreLabel.position = CGPointMake(SCORELABEL_PADDING, wins.height / 2.0);
	scoreLabel.rotation = -90.0;
}

- (void)rotateInterfaceLandscapeLeft {
	CGSize wins = [[CCDirector sharedDirector] winSize]; 
	scoreLabel.position = CGPointMake(wins.width / 2.0, SCORELABEL_PADDING);
	scoreLabel.rotation = 180.0;
}

- (void)rotateInterfaceLandscapeRight {
	CGSize wins = [[CCDirector sharedDirector] winSize]; 
	scoreLabel.position = CGPointMake(wins.width / 2.0, wins.height - SCORELABEL_PADDING);
	scoreLabel.rotation = 0.0;
}

@end
