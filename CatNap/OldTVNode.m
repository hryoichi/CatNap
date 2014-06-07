//
//  OldTVNode.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/06/07.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "OldTVNode.h"
@import AVFoundation;

@interface OldTVNode ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) SKVideoNode *videoNode;

@end

@implementation OldTVNode

- (instancetype)initWithRect:(CGRect)frame {
    self = [super initWithImageNamed:@"tv"];

    if (self) {
        self.name = @"TVNode";

        SKSpriteNode *tvMaskNode =
        [SKSpriteNode spriteNodeWithImageNamed:@"tv-mask"];
        tvMaskNode.size = frame.size;
        SKCropNode *cropNode = [SKCropNode node];
        cropNode.maskNode = tvMaskNode;

        NSURL *fileURL = [NSURL fileURLWithPath:
            [[NSBundle mainBundle] pathForResource:@"BookTrailer" ofType:@"m4v"]];
        _player = [AVPlayer playerWithURL:fileURL];

        _videoNode = [[SKVideoNode alloc] initWithAVPlayer:_player];
        _videoNode.size = CGRectInset(frame, frame.size.width * 0.15f, frame.size.height * 0.27f).size;
        _videoNode.position = CGPointMake(-frame.size.width * 0.1f, -frame.size.height * 0.06f);

        [cropNode addChild:_videoNode];
        [self addChild:cropNode];

        self.position = frame.origin;
        self.size = frame.size;

        _player.volume = 0.0f;
        [_videoNode play];
    }

    return self;
}

@end
