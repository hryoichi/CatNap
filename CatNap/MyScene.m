//
//  MyScene.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/05/23.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "MyScene.h"
#import "SKSpriteNode+DebugDraw.h"

@interface MyScene ()

@property (nonatomic, strong) SKNode *gameNode;
@property (nonatomic, strong) SKSpriteNode *catNode;
@property (nonatomic, strong) SKSpriteNode *bedNode;
@property (nonatomic, assign) NSInteger currentLevel;

@end

@implementation MyScene

#pragma mark - Lifecycle

- (instancetype)initWithSize:(CGSize)size {
    self = [super initWithSize:size];

    if (self) {
        [self p_initialzeScene];
    }

    return self;
}

- (void)update:(CFTimeInterval)currentTime {
}

#pragma mark - Private

- (void)p_initialzeScene {
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];

    SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
    bg.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:bg];

    [self p_addCatBed];
}

- (void)p_addCatBed {
    _bedNode = [SKSpriteNode spriteNodeWithImageNamed:@"cat_bed"];
    _bedNode.position = CGPointMake(270.0f, 15.0f);
    [self addChild:_bedNode];

    CGSize contactSize = CGSizeMake(40.0f, 30.0f);
    _bedNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:contactSize];
    _bedNode.physicsBody.dynamic = NO; // Make the body static

    [_bedNode attachDebugRectWithSize:contactSize];
}

@end
