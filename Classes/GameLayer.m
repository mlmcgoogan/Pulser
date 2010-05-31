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


#pragma mark -
#pragma mark Chipmunk Callbacks

// Declarations
static void postStepMeteorRemoval(cpSpace *space, cpShape *shape, void *unused);
static void postStepTouchNodeRemoval(cpSpace *space, cpShape *shape, void *unused);

// Updating sprites
static void
eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	id node = shape->data;
	if( node ) {
		cpBody *body = shape->body;
		
		[node setPosition: body->p];
		[node setRotation: (float) CC_RADIANS_TO_DEGREES( -body->a )];
		
		if (unused != NULL && [node respondsToSelector:@selector(tintNodeBasedOnMeteorProximity:)]) {
			PulseNode *pNode = (PulseNode *)unused;
			NSArray *meteors = [NSArray arrayWithArray:pNode.meteors];
			
			[node tintNodeBasedOnMeteorProximity:meteors];
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
	PulseNode *pNode = (PulseNode *)unused;
	MeteorNode *mNode = (MeteorNode *)shape->data;
	[pNode removeMeteor:mNode];
	
	cpSpaceRemoveBody(space, shape->body);
	cpBodyFree(shape->body);
	
	cpSpaceRemoveShape(space, shape);
	cpShapeFree(shape);
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
	PulseNode *pNode = (PulseNode *)gLayer.pulseNode;
	
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepTouchNodeRemoval, touchNode, gLayer);
	cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepMeteorRemoval, meteor, pNode);
	
	[gLayer addCollisionAtPosition:cpArbiterGetPoint(arb, 0)];
	
	return 1;
}

static void
postStepTouchNodeRemoval(cpSpace *space, cpShape *shape, void *unused)
{
	TouchNode *tNode = (TouchNode *)shape->data;
	GameLayer *gLayer = (GameLayer *)unused;
	
	[gLayer removeChild:tNode cleanup:YES];
	[gLayer.touchNodeSheet removeChild:tNode.sprite cleanup:YES];
	[gLayer.player removeTouchNode:tNode];
	
	cpSpaceRemoveBody(space, shape->body);
	cpBodyFree(shape->body);
	
	cpSpaceRemoveShape(space, shape);
	cpShapeFree(shape);
}

#pragma mark -
#pragma mark 


@implementation GameLayer

@synthesize pulseNode, player, touchNodeSheet;

- (id)init {
	if ((self = [super init])) {
		
		srandom(time(NULL));
		self.isTouchEnabled = YES;
		
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
		
		player = [[Player alloc] init];
		[player setColor:[UIColor colorWithRed:0.259 green:0.404 blue:0.875 alpha:1.0]];
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		pulseNode = [[PulseNode alloc] initWithPosition:CGPointMake(85.0, (s.height / 2.0)) space:space];
		pulseNode.player = player;
		
		
		touchNodeSheet = [[CCSpriteSheet alloc] initWithFile:@"touchNode_144.png" capacity:10];
		[self addChild:touchNodeSheet];
		
		for (int i=0 ; i<1 ; i++) {
			CGFloat x = (float)(random() % 700) + 200.0;
			CGFloat y = (float)(random() % 500) + 100.0;
			TouchNode *node = [TouchNode nodeWithPosition:ccp(x,y) sheet:touchNodeSheet space:space];
			[self addChild:node];
			[player addTouchNode:node];
		}
		
		scoreLabel = [CCLabel labelWithString:@"Score: 000000" fontName:@"Helvetica" fontSize:24.0];
		scoreLabel.position = ccp(wins.width / 2.0, wins.height - 24.0);
		[self addChild:scoreLabel];
		
		/**
		 * Collision Callbacks
		 **/
		
		// Setup meteors for removal on collision with sensors
		cpSpaceAddCollisionHandler(space, REMOVAL_SENSOR_COL_GROUP, METEOR_COL_GROUP, meteorRemovalBegin, NULL, NULL, NULL, pulseNode);
		cpSpaceAddCollisionHandler(space, BOUNDARY_COL_GROUP, METEOR_COL_GROUP, meteorBoundaryIgnoreBegin, NULL, NULL, NULL, NULL);
		cpSpaceAddCollisionHandler(space, METEOR_COL_GROUP, TOUCHNODE_COL_GROUP, meteorTouchCollisionBegin, NULL, NULL, NULL, self);
		
		[self addChild:pulseNode];
	}
	
	return self;
}

- (void)dealloc {
	[touchNodeSheet release];
	[player release];
	[pulseNode release];
	[super dealloc];
}

- (void)onEnter {
	[super onEnter];
	[self schedule:@selector(mainStep:)];
	[self schedule:@selector(addTouchNodeStep:) interval:5.0];
	[self schedule:@selector(scoreStep:) interval:1.0/5.0];
}

- (void)onExit {
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
	
	cpSpaceHashEach(space->activeShapes, &eachShape, pulseNode);
	cpSpaceHashEach(space->staticShapes, &eachShape, NULL);
}

- (void)scoreStep:(ccTime)dt {
	score++;
	[scoreLabel setString:[NSString stringWithFormat:@"Score: %06d", score]];
	
	if (score == 200) {
		PulseNode *pNode = [[PulseNode alloc] initWithPosition:pulseNode.particleSystem.position space:space];
		pNode.player = player;
		[self addChild:pNode];
		[pNode release];
	}
}

#pragma mark -
#pragma mark Displaying a collision

- (void)addCollisionAtPosition:(CGPoint)pos {
	CCParticleSystem *pSys = [[[CCParticleExplosion alloc] initWithTotalParticles:200] autorelease];
	pSys.position = pos;
	pSys.gravity = CGPointZero;
	pSys.startColor = ccc4FFromccc4B(ccc4(51,102,179,255));
	pSys.startColorVar = ccc4FFromccc4B(ccc4(10,10,50,0));
	pSys.endColor = ccc4FFromccc4B(ccc4(0,0,0,255));
	pSys.blendAdditive = YES;
	[self addChild:pSys];
}

#pragma mark -
#pragma mark Adding TouchNodes

- (void)addTouchNodeStep:(ccTime)dt {
	[self addTouchNode];
}

- (void)addTouchNode {
	CGFloat x = (float)(random() % 700) + 200.0;
	CGFloat y = (float)(random() % 500) + 100.0;
	TouchNode *node = [TouchNode nodeWithPosition:ccp(x,y) sheet:touchNodeSheet space:space];
	[self addChild:node];
	[player addTouchNode:node];
}

#pragma mark -
#pragma mark Handling touches

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in [touches allObjects]) {
		CGPoint pos = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
		[self applyNavigationPulse:pos];
	}
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


@end
