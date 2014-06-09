//
//  CustomTransitionFilter.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/06/09.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "CustomTransitionFilter.h"

@implementation CustomTransitionFilter

- (CIImage *)outputImage {
    CIFilter *color = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    [color setValue:[CIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:self.inputTime]
         forKeyPath:@"inputColor"];

    CIFilter *blendWithMask = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
    [blendWithMask setValue:color.outputImage forKeyPath:@"inputMaskImage"];
    [blendWithMask setValue:self.inputImage forKeyPath:@"inputBackgroundImage"];
    [blendWithMask setValue:self.inputTargetImage forKeyPath:@"inputImage"];

    CIFilter *spinFilter = [CIFilter filterWithName:@"CIAffineTransform"];
    [spinFilter setValue:blendWithMask.outputImage forKeyPath:kCIInputImageKey];

    CGAffineTransform t = CGAffineTransformMakeRotation(self.inputTime * 3.14 * 4.0);
    NSValue *transformValue = [NSValue valueWithCGAffineTransform:t];
    [spinFilter setValue:transformValue forKeyPath:@"inputTransform"];

    return spinFilter.outputImage;
}

@end
