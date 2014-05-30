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
    CNPhysicsCategoryCat   = 1 << 0,  // 00001 = 1
    CNPhysicsCategoryBlock = 1 << 1,  // 00010 = 2
    CNPhysicsCategoryBed   = 1 << 2,  // 00100 = 4
    CNPhysicsCategoryEdge  = 1 << 3,  // 01000 = 8
    CNPhysicsCategoryLabel = 1 << 4,  // 10000 = 16
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

#pragma mark - Private (Initialization)

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
    _catNode.physicsBody.collisionBitMask = CNPhysicsCategoryBlock | CNPhysicsCategoryEdge;

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

#pragma mark - Private

- (void)p_inGameMessage:(NSString *)text {
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    label.text = text;
    label.fontSize = 64.0f;
    label.color = [SKColor whiteColor];
    label.position = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) - 10.0f);
    label.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:10.0f];
    label.physicsBody.collisionBitMask = CNPhysicsCategoryEdge;
    label.physicsBody.categoryBitMask = CNPhysicsCategoryLabel;
    label.physicsBody.contactTestBitMask = CNPhysicsCategoryEdge;
    label.physicsBody.restitution = 0.7f;

    [self.gameNode addChild:label];
}

- (void)p_newGame {
    [self.gameNode removeAllChildren];
    [self p_setupLevel:self.currentLevel];
    [self p_inGameMessage:[NSString stringWithFormat:@"Level %i", self.currentLevel]];
}

- (void)p_lose {
    // Disable further contact detection
    self.catNode.physicsBody.contactTestBitMask = 0;
    self.catNode.texture = [SKTexture textureWithImageNamed:@"cat_awake"];

    [[SKTAudio sharedInstance] pauseBackgroundMusic];
    [self runAction:[SKAction playSoundFileNamed:@"lose.mp3" waitForCompletion:NO]];

    [self p_inGameMessage:@"Try again ..."];

    [self runAction:[SKAction sequence:@[
        [SKAction waitForDuration:5.0],
        [SKAction performSelector:@selector(p_newGame) onTarget:self]
    ]]];
}

- (void)p_win {
    self.catNode.physicsBody = nil;

    CGFloat curlY = self.bedNode.position.y + self.catNode.size.height / 2;
    CGPoint curlPoint = CGPointMake(self.bedNode.position.x, curlY);

    [self.catNode runAction:[SKAction group:@[
        [SKAction moveTo:curlPoint duration:0.66],
        [SKAction rotateToAngle:0.0f duration:0.5]
    ]]];

    [self p_inGameMessage:@"Good job!"];

    [self runAction:[SKAction sequence:@[
        [SKAction waitForDuration:5.0],
        [SKAction performSelector:@selector(p_newGame) onTarget:self]
    ]]];

    [self.catNode runAction:[SKAction animateWithTextures:@[
        [SKTexture textureWithImageNamed:@"cat_curlup1"],
        [SKTexture textureWithImageNamed:@"cat_curlup2"],
        [SKTexture textureWithImageNamed:@"cat_curlup3"]
    ] timePerFrame:0.25]];

    [[SKTAudio sharedInstance] pauseBackgroundMusic];
    [self runAction:[SKAction playSoundFileNamed:@"win.mp3" waitForCompletion:NO]];
}

#pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact {
    NSUInteger collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask);

    if (collision == (CNPhysicsCategoryCat | CNPhysicsCategoryBed)) {
        [self p_win];
    }

    if (collision == (CNPhysicsCategoryCat | CNPhysicsCategoryEdge)) {
        [self p_lose];
    }

    if (collision == (CNPhysicsCategoryLabel | CNPhysicsCategoryEdge)) {
        SKLabelNode *label;

        if (contact.bodyA.categoryBitMask == CNPhysicsCategoryLabel) {
            label = (SKLabelNode *)contact.bodyA.node;
        }
        else {
            label = (SKLabelNode *)contact.bodyB.node;
        }

        if (!label.userData) {
            label.userData = [@{@"bounceCount": @0} mutableCopy];
        }

        NSInteger newBounceCount = [label.userData[@"bounceCount"] integerValue] + 1;
        NSLog(@"bounce: %i", newBounceCount);

        if (newBounceCount < 4) {
            label.userData = [@{@"bounceCount": @(newBounceCount)} mutableCopy];
        }
        else {
            [label removeFromParent];
        }
    }
}

@end
