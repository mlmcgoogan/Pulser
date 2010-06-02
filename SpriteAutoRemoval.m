//
//  SpriteAutoRemoval.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 6/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SpriteAutoRemoval.h"


@implementation CCSprite (AutoRemovalMethods)

- (void)removeFromParent {
	[self.parent removeChild:self cleanup:YES];
}

@end
