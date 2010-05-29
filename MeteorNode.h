//
//  MeteorNode.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "chipmunk.h"

#define METEOR_MASS 10.0f
#define METEOR_RADIUS 30.0f

@interface MeteorNode : CCNode {
	cpShape *shape;
	
	CCParticleSystem *particleSystem;
	CGPoint start;
	CGPoint unitVector;
	
	@private
	ccTime travelLife;
}

@property (nonatomic, readonly) cpShape *shape;
@property (nonatomic, retain) CCParticleSystem *particleSystem;
@property (nonatomic, assign) CGPoint start;
@property (nonatomic, assign) CGPoint unitVector;

- (id)initWithStart:(CGPoint)startPos direction:(CGPoint)dirUnitVec space:(cpSpace *)space;

@end
