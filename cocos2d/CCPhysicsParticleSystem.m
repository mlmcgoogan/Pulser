/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */


// opengl
#import <OpenGLES/ES1/gl.h>

// cocos2d
#import "CCPhysicsParticleSystem.h"
#import "CCTextureCache.h"
#import "ccMacros.h"
#import "CCDirector.h"
#import "ccTypes.h"

// support
#import "Support/OpenGL_Internal.h"
#import "Support/CGPointExtension.h"

#import "Constants.h"

NSArray *enemiesRef = nil;

#pragma mark Chipmunk Velocity damping
static void
dampingVelocityFunc(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt)
{
	damping = 0.999;
	
	id closest = nil;
	for (id ccObject in enemiesRef) {
		if (closest == nil)
			closest = ccObject;
		else {
			float dist = fabsf(ccpDistance(body->p, [ccObject position]));
			if (dist < fabsf(ccpDistance(body->p, [closest position]))) {
				closest = ccObject;
			}
		}
	}
	
	if (closest != nil) {
		cpVect sub = cpvsub(body->p, [closest position]);
		float dist = fabsf(cpvdist(body->p, [closest position]));
		sub = cpvmult(sub, 5000.0);
		gravity = cpvmult(sub, 1/(dist*dist));
	}

		
	cpBodyUpdateVelocity(body, gravity, damping, dt);
}


@implementation CCPhysicsParticleSystem

@synthesize texture;

-(id) initWithTotalParticles:(int)numberOfParticles chipmunkSpace:(cpSpace *)aSpace {
	if( (self=[super init]) ) {
		
		self.anchorPoint = ccp(0,0);
		enemies = [[NSMutableArray alloc] init];
		
		totalParticleCount = numberOfParticles;
		vertices = malloc( sizeof(ccPhysicsPointSprite) * numberOfParticles );
		space = aSpace;
		
		[self initParticles];
		
		self.texture = [[CCTextureCache sharedTextureCache] addImage:@"fire.png"];
		blendFunc.src = CC_BLEND_SRC;
		blendFunc.dst = CC_BLEND_DST;
		
		if( ! vertices ) {
			NSLog(@"cocos2d: Particle system: not enough memory");
			[self release];
			return nil;
		}
		
		glGenBuffers(1, &verticesID);
		
		// initial binding
		glBindBuffer(GL_ARRAY_BUFFER, verticesID);
		glBufferData(GL_ARRAY_BUFFER, sizeof(ccPhysicsPointSprite)*numberOfParticles, vertices,GL_DYNAMIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);		
	}
	
	return self;
}

-(void) dealloc
{
	free(vertices);
	glDeleteBuffers(1, &verticesID);
	
	[enemies release];
	[enemiesRef release];
	
	[super dealloc];
}

- (void)initParticles {
	
	CGSize wins = [[CCDirector sharedDirector] winSize];
	
	for (int i=0 ; i < totalParticleCount ; i++) {
		ccPhysicsPointSprite *point = &vertices[i];
		
		point->pos = ccp(CCRANDOM_0_1() * wins.width, CCRANDOM_0_1() * wins.height);
		point->colors.r = 0.0;
		point->colors.g = CCRANDOM_0_1();
		point->colors.b = 0.6;
		point->colors.a = 1.0;
		point->size = 4.0;
		point->index = i;
		
		cpBody *body = cpBodyNew(5.0, INFINITY);
		body->p = point->pos;
		body->velocity_func = dampingVelocityFunc;
		cpSpaceAddBody(space, body);
		
		cpShape *shape = cpCircleShapeNew(body, 2.0, cpvzero);
		shape->u = 0.2;
		shape->e = 0.9;
		shape->data = point;
		shape->collision_type = PARTICLE_COL_GROUP;
		cpSpaceAddShape(space, shape);
		
		//NSLog(@"INIT (%02f, %02f)", point->pos.x, point->pos.y);
	}
}

/*
-(void) updateQuadWithParticle:(tCCParticle*)p newPosition:(CGPoint)newPos
{
	// place vertices and colos in array
	vertices[particleIdx].pos = newPos;
	vertices[particleIdx].size = p->size;
	vertices[particleIdx].colors = p->color;
}*/

-(void) postStep
{
	if ([enemies count] > 0) {		
		for (int i=0 ; i < totalParticleCount ; i++) {
			ccPhysicsPointSprite *point = &vertices[i];
			
			float closestDist = 1024.0;
			for (id *ccObject in enemies) {
				float dist = ccpDistance([ccObject position], point->pos);
				if (dist < closestDist)
					closestDist = dist;
			}
			
			if (closestDist > 200.0) {
				point->colors.r = 0.0;
				point->size = 3.0;
			}
			else {
				point->colors.r =  (1024.0-closestDist) / (1024.0);
				point->size = 5.0;
			}
		}
	}
	
	glBindBuffer(GL_ARRAY_BUFFER, verticesID);
	glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(ccPhysicsPointSprite)*totalParticleCount, vertices);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

-(void) draw
{
    if (totalParticleCount==0)
        return;
	
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY
	// Unneeded states: GL_TEXTURE_COORD_ARRAY
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glBindTexture(GL_TEXTURE_2D, texture.name);
	
	glEnable(GL_POINT_SPRITE_OES);
	glTexEnvi( GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE );	
	
	glBindBuffer(GL_ARRAY_BUFFER, verticesID);

	glVertexPointer(2,GL_FLOAT,sizeof(vertices[0]),0);

	glColorPointer(4, GL_FLOAT, sizeof(vertices[0]),(GLvoid*) offsetof(ccPhysicsPointSprite,colors) );

	glEnableClientState(GL_POINT_SIZE_ARRAY_OES);
	glPointSizePointerOES(GL_FLOAT,sizeof(vertices[0]),(GLvoid*) offsetof(ccPhysicsPointSprite,size) );
	

	BOOL newBlend = NO;
	if( blendFunc.src != CC_BLEND_SRC || blendFunc.dst != CC_BLEND_DST ) {
		newBlend = YES;
		glBlendFunc( blendFunc.src, blendFunc.dst );
	}

	// save color mode
#if 0
	glGetTexEnviv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, &colorMode);
	if( colorModulate )
		glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
	else
		glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE );
#endif

	glDrawArrays(GL_POINTS, 0, totalParticleCount);
	
	// restore blend state
	if( newBlend )
		glBlendFunc( CC_BLEND_SRC, CC_BLEND_DST);

#if 0
	// restore color mode
	glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, colorMode);
#endif
	
	// unbind VBO buffer
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	glDisableClientState(GL_POINT_SIZE_ARRAY_OES);
	glDisable(GL_POINT_SPRITE_OES);

	// restore GL default state
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void)addEnemy:(id)ccObject {
	if ([ccObject respondsToSelector:@selector(position)]) {
		[enemies addObject:ccObject];
		
		[enemiesRef release];
		enemiesRef = [[NSArray alloc] initWithArray:enemies];
	}
}

- (void)removeEnemy:(id)ccObject {
	[enemies removeObject:ccObject];
	[enemiesRef release];
	enemiesRef = [[NSArray alloc] initWithArray:enemies];
}

@end


