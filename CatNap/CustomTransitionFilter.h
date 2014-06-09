//
//  CustomTransitionFilter.h
//  CatNap
//
//  Created by Ryoichi Hara on 2014/06/09.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

@import CoreImage;

@interface CustomTransitionFilter : CIFilter

@property (nonatomic, strong) CIImage *inputImage;        // the source scene
@property (nonatomic, strong) CIImage *inputTargetImage;  // the destination scene
@property (nonatomic, assign) NSTimeInterval inputTime;   // range from 0.0 to 1.0

@end
