//
//  SpriteAutoRemoval.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 6/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CCSprite (AutoRemovalMethods)

- (void)removeFromParent;

@end
