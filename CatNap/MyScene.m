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
#import "SKTUtils.h"
#import "OldTVNode.h"
#import "Physics.h"

@interface MyScene () <SKPhysicsContactDelegate>

@property (nonatomic, strong) SKNode *gameNode;
@property (nonatomic, strong) SKSpriteNode *catNode;
@property (nonatomic, strong) SKSpriteNode *bedNode;
@property (nonatomic, assign) NSInteger currentLevel;
@property (nonatomic, assign, getter = isHooked) BOOL hooked;
@property (nonatomic, strong) SKSpriteNode *hookBaseNode;
@property (nonatomic, strong) SKSpriteNode *hookNode;
@property (nonatomic, strong) SKSpriteNode *ropeNode;

@end

SKT_INLINE CGPoint adjustPoint(CGPoint inputPoint, CGSize inputSize) {
    // the Maximum height and widht of deviation (15% of width or height)
    CGFloat width = inputSize.width * 0.15f;
    CGFloat height = inputSize.height * 0.15f;

    // Create a movement range
    CGFloat xMove = width * RandomFloat() - width / 2.0f;
    CGFloat yMove = height * RandomFloat() - height / 2.0f;

    // Add random movement amount to the input point
    return CGPointMake(inputPoint.x + xMove, inputPoint.y + yMove);
}

@implementation MyScene

#pragma mark - Lifecycle

- (instancetype)initWithSize:(CGSize)size {
    self = [super initWithSize:size];

    if (self) {
        [self p_initializeScene];
    }

    return self;
}

- (void)update:(CFTimeInterval)currentTime {
}

- (void)didSimulatePhysics {
    // Calculate the angle between the ceiling fixture and the hook
    CGFloat angle = CGPointToAngle(CGPointSubtract(_hookBaseNode.position, _hookNode.position));
    self.ropeNode.zRotation = M_PI + angle;

    if (!self.isHooked && self.catNode.physicsBody.contactTestBitMask &&
        fabs(self.catNode.zRotation) > DegreesToRadians(25)) {
        [self p_lose];
    }
}

#pragma mark - Actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];

    [self.physicsWorld enumerateBodiesAtPoint:location usingBlock:^(SKPhysicsBody *body, BOOL *stop) {
        if ([body.node.name isEqualToString:@"PhotoFrameNode"]) {

            if ([self.delegate respondsToSelector:@selector(requestImagePickcer)]) {
                [self.delegate requestImagePickcer];
            }
            *stop = YES;

            return;
        }

        if (body.categoryBitMask == CNPhysicsCategoryBlock) {

            for (SKPhysicsJoint *joint in body.joints) {
                [self.physicsWorld removeJoint:joint];
                [joint.bodyA.node removeFromParent];
                [joint.bodyB.node removeFromParent];
            }

            [body.node removeFromParent];
            *stop = YES;

            [self runAction:[SKAction playSoundFileNamed:@"pop.mp3" waitForCompletion:NO]];
        }

        if (body.categoryBitMask == CNPhysicsCategorySpring) {
            SKSpriteNode *spring = (SKSpriteNode *)body.node;

            [body applyImpulse:CGVectorMake(0.0f, 12.0f)
                       atPoint:CGPointMake(spring.size.width / 2, spring.size.height / 2)];
            [body.node runAction:[SKAction sequence:@[
                [SKAction waitForDuration:1.0],
                [SKAction removeFromParent]
            ]]];

            *stop = YES;
        }

        if (body.categoryBitMask == CNPhysicsCategoryCat && self.isHooked) {
            [self p_releaseHook];
        }
    }];
}

#pragma mark - Public

- (void)setPhotoTexture:(SKTexture *)texture {
    SKSpriteNode *picture = (SKSpriteNode *)[self childNodeWithName:@"//PictureNode"];
    [picture setTexture:texture];
}

#pragma mark - Private (Initialization)

- (void)p_initializeScene {
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    self.physicsBody.categoryBitMask = CNPhysicsCategoryEdge;

    SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
    bg.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:bg];

    SKSpriteNode *bg2 = [SKSpriteNode spriteNodeWithImageNamed:@"background-desat"];

    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Zapfino"];
    label.text = @"Cat Nap";
    label.fontSize = 96.0f;

    SKCropNode *cropNode = [SKCropNode node];
    [cropNode addChild:bg2];
    [cropNode setMaskNode:label];
    cropNode.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:cropNode];

    [self p_addCatBed];

    _gameNode = [SKNode node];
    [self addChild:_gameNode];

    _currentLevel = 7;
    [self p_setupLevel:_currentLevel];

    //OldTVNode *tvNode = [[OldTVNode alloc] initWithRect:CGRectMake(100.0f, 250.0f, 100.0f, 100.0f)];
    //[self addChild:tvNode];
}

- (void)p_setupLevel:(NSInteger)level {
    // Load the plist file
    NSString *fileName = [NSString stringWithFormat:@"level%li", (long)level];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    NSDictionary *levelParams = [NSDictionary dictionaryWithContentsOfFile:filePath];

    [self p_addCatAtPosition:CGPointFromString(levelParams[@"catPosition"])];
    [self p_addBlocksFromArray:levelParams[@"blocks"]];
    [self p_addSpringsFromArray:levelParams[@"springs"]];

    if (levelParams[@"hookPosition"]) {
        [self p_addHookAtPosition:CGPointFromString(levelParams[@"hookPosition"])];
    }

    if (levelParams[@"seesawPosition"]) {
        [self p_addSeesawAtPosition:CGPointFromString(levelParams[@"seesawPosition"])];
    }

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
    _catNode.physicsBody.collisionBitMask =
        CNPhysicsCategoryBlock | CNPhysicsCategoryEdge | CNPhysicsCategorySpring;

    // "contactTestBitMask": A mask that defines which categories of bodies cause intersection notifications with this physics body.
    _catNode.physicsBody.contactTestBitMask = CNPhysicsCategoryBed | CNPhysicsCategoryEdge;

    [_catNode attachDebugRectWithSize:contactSize];
}

- (void)p_addBlocksFromArray:(NSArray *)blocks {
    for (id block in blocks) {

        if ([block isKindOfClass:[NSDictionary class]]) {
            NSString *blockType = block[@"type"];

            if (!blockType) {

                if (block[@"tuple"]) {
                    CGRect rect1 = CGRectFromString([block[@"tuple"] firstObject]);
                    SKSpriteNode *block1 = [self p_addBlockWithRect:rect1];
                    block1.physicsBody.friction = 0.8f;
                    block1.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
                    block1.physicsBody.collisionBitMask =
                    CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;
                    [_gameNode addChild:block1];

                    CGRect rect2 = CGRectFromString([block[@"tuple"] lastObject]);
                    SKSpriteNode *block2 = [self p_addBlockWithRect:rect2];
                    block2.physicsBody.friction = 0.8f;
                    block2.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
                    block2.physicsBody.collisionBitMask =
                    CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;
                    [_gameNode addChild:block2];

                    [self.physicsWorld addJoint:[SKPhysicsJointFixed
                        jointWithBodyA:block1.physicsBody bodyB:block2.physicsBody anchor:CGPointZero]];
                }
                else {
                    SKSpriteNode *blockSprite = [self p_addBlockWithRect:CGRectFromString(block[@"rect"])];
                    blockSprite.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
                    blockSprite.physicsBody.collisionBitMask =
                    CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;
                    [_gameNode addChild:blockSprite];
                }
            }
            else {

                if ([blockType isEqualToString:@"PhotoFrameBlock"]) {
                    [self p_createPhotoFrameWithPosition:CGPointFromString(block[@"point"])];
                }
                else if ([blockType isEqualToString:@"TVBlock"]) {
                    [_gameNode addChild:[[OldTVNode alloc] initWithRect:CGRectFromString(block[@"rect"])]];
                }
                else if ([blockType isEqualToString:@"WonkyBlock"]) {
                    [_gameNode addChild:[self p_createWonkyBlockFromRect:CGRectFromString(block[@"rect"])]];
                }
            }
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

- (void)p_addSpringsFromArray:(NSArray *)springs {
    for (id spring in springs) {
        if ([spring isKindOfClass:[NSDictionary class]]) {
            SKSpriteNode *springSprite = [SKSpriteNode spriteNodeWithImageNamed:@"spring"];
            springSprite.position = CGPointFromString(spring[@"position"]);
            springSprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:springSprite.size];
            springSprite.physicsBody.categoryBitMask = CNPhysicsCategorySpring;
            springSprite.physicsBody.collisionBitMask =
                CNPhysicsCategoryEdge | CNPhysicsCategoryBlock | CNPhysicsCategoryCat;

            [springSprite attachDebugRectWithSize:springSprite.size];

            [_gameNode addChild:springSprite];
        }
    }
}

- (void)p_addHookAtPosition:(CGPoint)hookPosition {
    // Cleans up the instance variables and makes sure there is a hook object found in the .plist data.
    _hookBaseNode = nil;
    _hookNode = nil;
    _ropeNode = nil;

    _hooked = NO;

    _hookBaseNode = [SKSpriteNode spriteNodeWithImageNamed:@"hook_base"];
    _hookBaseNode.position = CGPointMake(
        hookPosition.x,
        hookPosition.y - (_hookBaseNode.size.height / 2)
    );
    _hookBaseNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_hookBaseNode.size];

    [_gameNode addChild:_hookBaseNode];

    SKPhysicsJointFixed *ceilingFix = [SKPhysicsJointFixed
        jointWithBodyA:_hookBaseNode.physicsBody bodyB:self.physicsBody anchor:CGPointZero];
    [self.physicsWorld addJoint:ceilingFix];

    _ropeNode = [SKSpriteNode spriteNodeWithImageNamed:@"rope"];
    _ropeNode.position = _hookBaseNode.position;

    // Make the sprite swing like a pendulum
    _ropeNode.anchorPoint = CGPointMake(0.0f, 0.5f);

    [_gameNode addChild:_ropeNode];

    _hookNode = [SKSpriteNode spriteNodeWithImageNamed:@"hook"];
    _hookNode.position = CGPointMake(hookPosition.x, hookPosition.y - 63.0f);
    _hookNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:(_hookNode.size.width / 2)];
    _hookNode.physicsBody.categoryBitMask = CNPhysicsCategoryHook;
    _hookNode.physicsBody.contactTestBitMask = CNPhysicsCategoryCat;
    _hookNode.physicsBody.collisionBitMask = kNilOptions;

    [_gameNode addChild:_hookNode];

    CGPoint anchorB = CGPointMake(
        _hookNode.position.x,
        _hookNode.position.y + (_hookNode.size.height / 2)
    );
    SKPhysicsJointSpring *ropeJoint =
    [SKPhysicsJointSpring jointWithBodyA:_hookBaseNode.physicsBody
                                   bodyB:_hookNode.physicsBody
                                 anchorA:_hookBaseNode.position
                                 anchorB:anchorB];
    [self.physicsWorld addJoint:ropeJoint];
}

- (void)p_addSeesawAtPosition:(CGPoint)position {
    SKSpriteNode *seesawFix = [SKSpriteNode spriteNodeWithImageNamed:@"45x45"];
    seesawFix.position = position;
    seesawFix.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:seesawFix.size];
    seesawFix.physicsBody.categoryBitMask = kNilOptions;
    seesawFix.physicsBody.collisionBitMask = kNilOptions;

    [_gameNode addChild:seesawFix];

    SKPhysicsJointFixed *fixJoint = [SKPhysicsJointFixed
        jointWithBodyA:seesawFix.physicsBody bodyB:self.physicsBody anchor:CGPointZero];
    [self.physicsWorld addJoint:fixJoint];

    SKSpriteNode *seesaw = [SKSpriteNode spriteNodeWithImageNamed:@"430x30"];
    seesaw.position = position;
    seesaw.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:seesaw.size];
    seesaw.physicsBody.collisionBitMask = CNPhysicsCategoryCat | CNPhysicsCategoryBlock;
    [seesaw attachDebugRectWithSize:seesaw.size];

    [_gameNode addChild:seesaw];

    SKPhysicsJointPin *pin = [SKPhysicsJointPin
        jointWithBodyA:seesawFix.physicsBody bodyB:seesaw.physicsBody anchor:position];
    [self.physicsWorld addJoint:pin];
}

- (SKShapeNode *)p_createWonkyBlockFromRect:(CGRect)inputRect {
    CGPoint origin = CGPointMake(
        CGRectGetMinX(inputRect) - CGRectGetWidth(inputRect) / 2.0f,
        CGRectGetMinY(inputRect) - CGRectGetHeight(inputRect) / 2.0f
    );

    // l: left, r: right, t: top, b: bottom
    CGPoint pointlb = origin;
    CGPoint pointlt = CGPointMake(origin.x, CGRectGetMinY(inputRect) + CGRectGetHeight(inputRect));

    CGPoint pointrb = CGPointMake(origin.x + CGRectGetWidth(inputRect), origin.y);
    CGPoint pointrt = CGPointMake(
        origin.x + CGRectGetWidth(inputRect),
        origin.y + CGRectGetHeight(inputRect)
    );

    pointlb = adjustPoint(pointlb, inputRect.size);
    pointlt = adjustPoint(pointlt, inputRect.size);
    pointrb = adjustPoint(pointrb, inputRect.size);
    pointrt = adjustPoint(pointrt, inputRect.size);

    UIBezierPath *shapeNodePath = [UIBezierPath bezierPath];
    [shapeNodePath moveToPoint:pointlb];
    [shapeNodePath addLineToPoint:pointlt];
    [shapeNodePath addLineToPoint:pointrt];
    [shapeNodePath addLineToPoint:pointrb];

    [shapeNodePath closePath];

    SKShapeNode *wonkyBlock = [SKShapeNode node];
    wonkyBlock.path = shapeNodePath.CGPath;

    // Make a physics body that's just a little smaller than the visual representation
    UIBezierPath *physicsBodyPath = [UIBezierPath bezierPath];
    [physicsBodyPath moveToPoint:CGPointSubtract(pointlb, CGPointMake(-2.0f, -2.0f))];
    [physicsBodyPath addLineToPoint:CGPointSubtract(pointlt, CGPointMake(-2.0f, 2.0f))];
    [physicsBodyPath addLineToPoint:CGPointSubtract(pointrt, CGPointMake(2.0f, 2.0f))];
    [physicsBodyPath addLineToPoint:CGPointSubtract(pointrb, CGPointMake(2.0f, -2.0f))];

    [physicsBodyPath closePath];

    // A polygon physics body must be a convex polygon
    wonkyBlock.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:physicsBodyPath.CGPath];
    wonkyBlock.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
    wonkyBlock.physicsBody.collisionBitMask =
        CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;

    wonkyBlock.lineWidth = 1.0f;
    wonkyBlock.fillColor = [UIColor colorWithRed:0.75f green:0.75f blue:1.0f alpha:1.0f];
    wonkyBlock.strokeColor = [UIColor colorWithRed:0.15f green:0.15f blue:0.0f alpha:1.0f];
    wonkyBlock.glowWidth = 1.0f;

    return wonkyBlock;
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
    [self p_inGameMessage:[NSString stringWithFormat:@"Level %li", (long)self.currentLevel]];
}

- (void)p_lose {
    if (self.currentLevel > 1) {
        self.currentLevel--;
    }

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
    if (self.currentLevel < 7) {
        self.currentLevel++;
    }

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

- (void)p_releaseHook {
    self.catNode.zRotation = 0.0f;

    [self.physicsWorld removeJoint:[self.hookNode.physicsBody.joints lastObject]];
    self.hooked = NO;
}

- (void)p_createPhotoFrameWithPosition:(CGPoint)position {
    SKSpriteNode *photoFrame = [SKSpriteNode spriteNodeWithImageNamed:@"picture-frame"];
    photoFrame.name = @"PhotoFrameNode";
    photoFrame.position = position;

    SKSpriteNode *pictureNode = [SKSpriteNode spriteNodeWithImageNamed:@"picture"];
    pictureNode.name =  @"PictureNode";

    SKSpriteNode *maskNode = [SKSpriteNode spriteNodeWithImageNamed:@"picture-frame-mask"];
    maskNode.name = @"Mask";

    SKCropNode *cropNode = [SKCropNode node];
    [cropNode addChild:pictureNode];
    [cropNode setMaskNode:maskNode];

    [photoFrame addChild:cropNode];

    [_gameNode addChild:photoFrame];

    photoFrame.physicsBody = [SKPhysicsBody
        bodyWithCircleOfRadius:photoFrame.size.width / 2.0f - photoFrame.size.width * 0.025f];
    photoFrame.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
    photoFrame.physicsBody.collisionBitMask =
        CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;

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
        NSLog(@"bounce: %li", (long)newBounceCount);

        if (newBounceCount < 4) {
            label.userData = [@{@"bounceCount": @(newBounceCount)} mutableCopy];
        }
        else {
            [label removeFromParent];
        }
    }

    if (collision == (CNPhysicsCategoryHook | CNPhysicsCategoryCat)) {
        self.catNode.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
        self.catNode.physicsBody.angularVelocity = 0.0f;

        CGPoint anchor = CGPointMake(
            self.hookNode.position.x,
            self.hookNode.position.y + (self.hookNode.size.height / 2)
        );
        SKPhysicsJointFixed *hookJoint = [SKPhysicsJointFixed
            jointWithBodyA:self.hookNode.physicsBody bodyB:self.catNode.physicsBody anchor:anchor];
        [self.physicsWorld addJoint:hookJoint];

        self.hooked = YES;
    }
}

@end
