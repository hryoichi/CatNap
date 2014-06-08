//
//  OldTimeyFilter.m
//  CatNap
//
//  Created by Ryoichi Hara on 2014/06/08.
//  Copyright (c) 2014年 Ryoichi Hara. All rights reserved.
//

#import "OldTimeyFilter.h"
#import "perlin.h"

@implementation OldTimeyFilter

- (CIImage *)outputImage {
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    float v1[] = {sin(time / 15.0) * 100, 1.5};
    float v2[] = {sin(time / 2.0) * 25, 1.5};
    double randVal1 = noise2(v1);
    double randVal2 = noise2(v2);

    CIFilter *colorControls = [CIFilter filterWithName:@"CIColorControls"];
    [colorControls setValue:@(0.0) forKey:@"inputSaturation"];
    [colorControls setValue:@(randVal2 * 0.2) forKey:@"inputBrightness"];

    CIFilter *vignette = [CIFilter filterWithName:@"CIVignette"];
    [vignette setValue:@(0.2 + randVal2) forKey:@"inputRadius"];
    [vignette setValue:@(randVal2 * 0.2 + 0.8) forKey:@"inputIntensity"];

    CIFilter *transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
    CGAffineTransform t = CGAffineTransformMakeTranslation(0.0, randVal1 * 45.0);
    NSValue *transform = [NSValue valueWithCGAffineTransform:t];
    [transformFilter setValue:transform forKey:@"inputTransform"];

    // CIFilter chains
    [colorControls setValue:self.inputImage forKey:kCIInputImageKey];
    [vignette setValue:colorControls.outputImage forKey:kCIInputImageKey];
    [transformFilter setValue:vignette.outputImage forKey:kCIInputImageKey];

    return transformFilter.outputImage;
}

@end
