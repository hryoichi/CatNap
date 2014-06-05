//
//  ViewController.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/05/23.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@interface ViewController () <ImageCaptureDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // Configure the view.
    SKView * skView = (SKView *)self.view;

    if (!skView.scene) {
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;

        // Create and configure the scene.
        MyScene *scene = [MyScene sceneWithSize:skView.bounds.size];
        scene.delegate = self;
        scene.scaleMode = SKSceneScaleModeAspectFill;

        // Present the scene.
        [skView presentScene:scene];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ImageCaptureDelegate

- (void)requestImagePickcer {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;

    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];

    [picker dismissViewControllerAnimated:YES completion:^{
        SKTexture *imageTexture = [SKTexture textureWithImage:image];

        SKView *view = (SKView *)self.view;
        MyScene *currentScene = (MyScene *)[view scene];

        // Place core image code here
        [currentScene setPhotoTexture:imageTexture];
    }];
}

@end
