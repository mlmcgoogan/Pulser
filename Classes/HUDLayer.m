//
//  HUDLayer.m
//  Pulser
//
//  Created by Matthew Mcgoogan on 8/2/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "HUDLayer.h"


@implementation HUDLayer

- (id)init {
    if (self = [super init]) {
        CGSize wins = [[CCDirector sharedDirector] winSize];
        
        scoreNode = [[CCNode node] retain];
        scoreNode.anchorPoint = ccp(0.5,0.5);
        scoreNode.position = ccp(wins.width/2.0, wins.height/2.0);
        
        scoreLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"000000" fntFile:@"STFangsong.fnt"] retain];
        CCSprite *scoreBG = [CCSprite spriteWithFile:@"hud_score.png"];
        CCRenderTexture *renderTex = [CCRenderTexture renderTextureWithWidth:250 height:128];
        
        
        
    }
}

- (void)dealloc {
    [scoreLabel release];
    [super dealloc];
}

@end
