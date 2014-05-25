//
//  SKSpriteNode+DebugDraw.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/05/25.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "SKSpriteNode+DebugDraw.h"

// Disable debug drawing by setting this to NO
static BOOL kDebugDraw = YES;

@implementation SKSpriteNode (DebugDraw)

- (void)attachDebugFrameFromPath:(CGPathRef)bodyPath {
    if (!kDebugDraw) return;

    SKShapeNode *shape = [SKShapeNode node];
    shape.path = bodyPath;
    shape.strokeColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
    shape.lineWidth = 1.0f;

    [self addChild:shape];
}

- (void)attachDebugRectWithSize:(CGSize)size {
    CGPathRef bodyPath = CGPathCreateWithRect(
        CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), nil);

    [self attachDebugFrameFromPath:bodyPath];
    CGPathRelease(bodyPath);
}

@end
