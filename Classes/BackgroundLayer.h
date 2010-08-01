//
//  BackgroundLayer.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCQuadPhysicsParticleSystem.h"

@interface BackgroundLayer : CCLayer {
	CCQuadPhysicsParticleSystem *particleSystem;
	
	@private
	cpSpace *_space;
}

@property (nonatomic, retain) CCQuadPhysicsParticleSystem *particleSystem;

- (id)initWithSpace:(cpSpace *)space;
- (void)update;

@end
