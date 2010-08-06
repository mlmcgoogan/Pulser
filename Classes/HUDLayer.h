//
//  HUDLayer.h
//  Pulser
//
//  Created by Matthew Mcgoogan on 8/2/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@interface HUDLayer : CCNode {
    CCSprite *scoreNode;
    CCBitmapFontAtlas *scoreLabel;
}

@end
