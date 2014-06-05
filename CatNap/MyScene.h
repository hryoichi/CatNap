//
//  MyScene.h
//  CatNap
//

//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

@import SpriteKit;

@protocol ImageCaptureDelegate <NSObject>

- (void)requestImagePickcer;

@end

@interface MyScene : SKScene

@property (nonatomic, assign) id <ImageCaptureDelegate> delegate;

/**
 *  Replace the texture for the existing SKSpriteNode that contains the image in the photo frame node.
 *
 *  @param texture
 */
- (void)setPhotoTexture:(SKTexture *)texture;

@end
