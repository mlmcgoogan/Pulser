//
//  PulseNode.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "chipmunk.h"
@class GameLayer;
@class MeteorNode;
@class Player;

#define PULSENODE_RADIUS 50.0f
#define PULSENODE_MASS 50.0f

typedef enum PulseNodeTypes {
    kmMeteorPulseNodeType,
    kmGravityWellPulseNodeType,
    kmLargePulseNodeType,
    kmSpeedPulseNodeType
} PulseNodeType;

@interface PulseNode : CCLayer {
	CCPointParticleSystem *particleSystem;
	cpShape *shape;
	NSMutableArray *meteors;
	Player *player;
	GameLayer *controller;
    PulseNodeType type;
	
	@private
	cpSpace *_space;
	CGPoint currentDestination;
	cpBody *pathBody;
	cpConstraint *joint;
	
	CCSprite *outer,*middle,*inner;
}

@property (nonatomic, retain) CCPointParticleSystem *particleSystem;
@property (nonatomic, readonly) NSMutableArray *meteors;
@property (nonatomic, retain) Player *player;
@property (nonatomic, retain) GameLayer *controller;
@property (nonatomic, readonly) PulseNodeType type;

- (id)initWithPosition:(CGPoint)pos space:(cpSpace *)space type:(PulseNodeType)aType;
- (id)initWithPosition:(CGPoint)pos space:(cpSpace *)space;

- (void)initMeteorType;
- (void)initGravityWellType;

- (CGPoint)randomPoint;
- (void)removeMeteor:(MeteorNode *)meteor;

// Removing PulseNode
- (void)prepForRemoval;

@end
