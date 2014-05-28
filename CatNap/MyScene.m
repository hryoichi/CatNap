//
//  MyScene.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/05/23.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "MyScene.h"
#import "SKSpriteNode+DebugDraw.h"
#import "SKTAudio.h"

typedef NS_OPTIONS(NSUInteger, CNPhysicsCategory) {
    CNPhysicsCategoryCat   = 1 << 0,  // 0001 = 1
    CNPhysicsCategoryBlock = 1 << 1,  // 0010 = 2
    CNPhysicsCategoryBed   = 1 << 2,  // 0100 = 4
    CNPhysicsCategoryEdge  = 1 << 3,  // 1000 = 8
};

@interface MyScene () <SKPhysicsContactDelegate>

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

#pragma mark - Actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];

    [self.physicsWorld enumerateBodiesAtPoint:location usingBlock:^(SKPhysicsBody *body, BOOL *stop) {
        if (body.categoryBitMask == CNPhysicsCategoryBlock) {
            [body.node removeFromParent];
            *stop = YES;

            [self runAction:[SKAction playSoundFileNamed:@"pop.mp3" waitForCompletion:NO]];
        }
    }];
}

#pragma mark - Private

- (void)p_initialzeScene {
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    self.physicsBody.categoryBitMask = CNPhysicsCategoryEdge;

    SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
    bg.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:bg];

    [self p_addCatBed];

    _gameNode = [SKNode node];
    [self addChild:_gameNode];

    _currentLevel = 1;
    [self p_setupLevel:_currentLevel];
}

- (void)p_setupLevel:(NSInteger)level {
    // Load the plist file
    NSString *fileName = [NSString stringWithFormat:@"level%i", level];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    NSDictionary *levelParams = [NSDictionary dictionaryWithContentsOfFile:filePath];

    [self p_addCatAtPosition:CGPointFromString(levelParams[@"catPosition"])];
    [self p_addBlocksFromArray:levelParams[@"blocks"]];

    [[SKTAudio sharedInstance] playBackgroundMusic:@"bgMusic.mp3"];
}

- (void)p_addCatBed {
    _bedNode = [SKSpriteNode spriteNodeWithImageNamed:@"cat_bed"];
    _bedNode.position = CGPointMake(270.0f, 15.0f);
    [self addChild:_bedNode];

    CGSize contactSize = CGSizeMake(40.0f, 30.0f);
    _bedNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:contactSize];
    _bedNode.physicsBody.dynamic = NO; // Make the body static
    _bedNode.physicsBody.categoryBitMask = CNPhysicsCategoryBed;

    [_bedNode attachDebugRectWithSize:contactSize];
}

- (void)p_addCatAtPosition:(CGPoint)position {
    // Add the cat in the level on its starting position
    _catNode = [SKSpriteNode spriteNodeWithImageNamed:@"cat_sleepy"];
    _catNode.position = position;

    [_gameNode addChild:_catNode];

    CGSize contactSize = CGSizeMake(_catNode.size.width - 40.0f, _catNode.size.height - 10.0f);
    _catNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:contactSize];
    _catNode.physicsBody.categoryBitMask = CNPhysicsCategoryCat;

    // "contactTestBitMask": A mask that defines which categories of bodies cause intersection notifications with this physics body.
    _catNode.physicsBody.contactTestBitMask = CNPhysicsCategoryBed | CNPhysicsCategoryEdge;

    [_catNode attachDebugRectWithSize:contactSize];
}

- (void)p_addBlocksFromArray:(NSArray *)blocks {
    for (id block in blocks) {
        if ([block isKindOfClass:[NSDictionary class]]) {
            SKSpriteNode *blockSprite = [self p_addBlockWithRect:CGRectFromString(block[@"rect"])];
            blockSprite.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
            blockSprite.physicsBody.collisionBitMask =
                CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;
            [_gameNode addChild:blockSprite];
        }
    }
}

- (SKSpriteNode *)p_addBlockWithRect:(CGRect)blockRect {
    NSString *textureName = [NSString
        stringWithFormat:@"%.fx%.f.png", CGRectGetWidth(blockRect), CGRectGetHeight(blockRect)];

    SKSpriteNode *blockSprite = [SKSpriteNode spriteNodeWithImageNamed:textureName];
    blockSprite.position = blockRect.origin;

    CGRect bodyRect = CGRectInset(blockRect, 2.0f, 2.0f);
    blockSprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bodyRect.size];

    [blockSprite attachDebugRectWithSize:blockRect.size];

    return blockSprite;
}

#pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact {
    NSUInteger collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask);

    if (collision == (CNPhysicsCategoryCat | CNPhysicsCategoryBed)) {
        NSLog(@"SUCCESS");
    }

    if (collision == (CNPhysicsCategoryCat | CNPhysicsCategoryEdge)) {
        NSLog(@"FAIL");
    }
}

@end
