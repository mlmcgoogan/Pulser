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
@class BackgroundLayer;

@interface GameLayer : CCLayer {
	cpSpace *space;
	
	BackgroundLayer *bgLayer;
	
	Player *player;
	NSMutableArray *pulseNodes;
	
	CCLabel *scoreLabel;
	
	CCSpriteSheet *blendSheet;
	CCSpriteSheet *noBlendSheet;
	
	@private
	int score;
	int gameRuntime;
}

@property (nonatomic, readonly) NSMutableArray *pulseNodes;
@property (nonatomic, readonly) Player *player;
@property (nonatomic, retain) CCSpriteSheet *blendSheet;
@property (nonatomic, retain) CCSpriteSheet *noBlendSheet;
@property (nonatomic, retain) BackgroundLayer *bgLayer;

// Chipmunk
- (void)mainStep:(ccTime) dt;

// Displaying collision
- (void)addCollisionAtPosition:(CGPoint)pos;

// Adding TouchNodes
- (void)addTouchNode;
- (void)addTouchNodeStep:(ccTime)dt;

// Primary game timer
- (void)gameStep:(ccTime) dt;

// Scoring
- (void)scoreStep:(ccTime)dt;

// Pulse Navigation
- (void)applyNavigationPulse:(CGPoint)pos;
- (void)displayTap:(CGPoint)pos;

// All meteors
- (NSArray *)allMeteors;

// Orientation changes
- (void)orientationDidChange:(NSNotification *)notification;
- (void)rotateInterfacePortrait;
- (void)rotateInterfacePortraitUpsideDown;
- (void)rotateInterfaceLandscapeLeft;
- (void)rotateInterfaceLandscapeRight;

@end
