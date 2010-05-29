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

#define TOUCHNODE_RADIUS 46.0f
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
	CCParticleSystem *particleSystem;
	Player *player;
	
	cpShape *shape;
	cpSpace *_space;
}

@property (nonatomic, retain) CCParticleSystem *particleSystem;
@property (nonatomic, retain) CCSprite *sprite;
@property (nonatomic, retain) Player *player;
@property (nonatomic, readonly) cpShape *shape;

// Initializing/Creating TouchNode
+ (id)nodeWithPosition:(CGPoint)pos sheet:(CCSpriteSheet *)sheet space:(cpSpace *)space;
- (id)initWithSpritePosition:(CGPoint)pos sheet:(CCSpriteSheet *)sheet space:(cpSpace *)space;
- (void)initSpriteWithPosition:(CGPoint)pos sheet:(CCSpriteSheet *)sheet;

// Chipmunk
- (void)setPosition:(CGPoint)pos;

// Changing color of node
- (void)tintNode:(UIColor *)color;
- (void)tintNodeBasedOnMeteorProximity:(NSArray *)meteors;


@end
