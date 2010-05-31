//
//  GameLayer.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "chipmunk.h"
@class Player;
@class PulseNode;

@interface GameLayer : CCLayer {
	cpSpace *space;
	
	Player *player;
	PulseNode *pulseNode;
	CCSpriteSheet *touchNodeSheet;
	
	CCLabel *scoreLabel;
	
	@private
	int score;
}

@property (nonatomic, readonly) PulseNode *pulseNode;
@property (nonatomic, readonly) Player *player;
@property (nonatomic, readonly) CCSpriteSheet *touchNodeSheet;

// Chipmunk
- (void)mainStep:(ccTime) dt;

// Displaying collision
- (void)addCollisionAtPosition:(CGPoint)pos;

// Adding TouchNodes
- (void)addTouchNode;
- (void)addTouchNodeStep:(ccTime)dt;

// Scoring
- (void)scoreStep:(ccTime)dt;

@end
