//
//  SKSpriteNode+DebugDraw.h
//  CatNap
//
//  Created by Ryoichi Hara on 2014/05/25.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

@import SpriteKit;

@interface SKSpriteNode (DebugDraw)

- (void)attachDebugFrameFromPath:(CGPathRef)bodyPath;
- (void)attachDebugRectWithSize:(CGSize)size;

@end
