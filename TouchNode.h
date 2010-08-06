//
//  TouchNode.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "chipmunk.h"
@class Player;
@class GameLayer;

#define TOUCHNODE_RADIUS 40.0f
#define TOUCHNODE_MASS 50.0f

typedef enum BoundType {
	BoundLeft,
	BoundRight,
	BoundTop,
	BoundBottom,
	BoundNone
} BoundType;

@interface TouchNode : CCLayer {
	CCSprite *sprite;
	CCSprite *center;
	CCPointParticleSystem *kamikazeSystem;
	Player *player;
	GameLayer *controller;
	
	
	cpShape *shape;
	cpSpace *_space;
	
	@private
	CGPoint touchStart;
	CGPoint touchCurrent;
	NSMutableArray *shells;
	
	NSTimer *kamikazeTimer;
	BOOL kamikazeModeActive;
}

@property (nonatomic, retain) CCSprite *sprite;
@property (nonatomic, retain) Player *player;
@property (nonatomic, readonly) cpShape *shape;
@property (nonatomic, retain) GameLayer *controller;

// Initializing/Creating TouchNode
+ (id)nodeWithPosition:(CGPoint)pos controller:(GameLayer *)gameController space:(cpSpace *)space;
- (id)initWithSpritePosition:(CGPoint)pos controller:(GameLayer *)gameController space:(cpSpace *)space;
- (void)initSpriteWithPosition:(CGPoint)pos;

// Kamikaze Mode
- (void)activateKamikaze;
- (void)deactivateKamikaze;

// Chipmunk
- (void)setPosition:(CGPoint)pos;

// Changing color of node
- (void)tintNode:(UIColor *)color;
- (void)tintNodeBasedOnMeteorProximity:(NSArray *)meteors;

- (void)prepForRemoval;


@end
