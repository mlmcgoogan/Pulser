//
//  Player.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "TouchNode.h"


@interface Player : NSObject {
	
	UIColor *color;
	
	
	@private
	NSMutableArray *touchNodes;
}

@property (nonatomic, readonly) UIColor *color;

- (void)setColor:(UIColor *)value;

- (void)addTouchNode:(TouchNode *)node;
- (BOOL)removeTouchNode:(TouchNode *)node;
- (NSArray *)touchNodes;

@end
