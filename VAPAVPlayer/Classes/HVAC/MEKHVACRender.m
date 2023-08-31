//
//  MEKHVACRender.m
//
//
//  Created by 江挺孙 on 2020/7/2.
//  Copyright © 2020 孙江挺. All rights reserved.
//

#import "MEKHVACRender.h"
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

CIImage *MEKHVACFixCIImageOriginal(CIImage *image) {
    CGPoint origin = image.extent.origin;
    return [image imageByApplyingTransform:CGAffineTransformMakeTranslation(-origin.x, -origin.y)];
}

#if !MEKTARGET_IS_SIMULATOR
#define MEKMETAL_ENABLED 1
#endif

#define STRINGIZE(x)    #x
#define STRINGIZE2(x)    STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const MEKHVACFilterFragmentShaderString = SHADER_STRING
(
 kernel vec4 mek_hvac_kernel_main(__sample s, __sample m) {
   return vec4(s.rgb, m.r);
 }
);

@interface MEKHVACRender ()

@end

@implementation MEKHVACRender

static CIKernel *_hvacKernel;

+ (CIKernel *)readKernelFromBundle {
    NSURL *kernelURL = nil;
    if (!kernelURL) {
        kernelURL = [[NSBundle mainBundle] URLForResource:@"hvac" withExtension:@"cikernel"];
    }
    NSError *error = nil;
    NSString *kernelString = [NSString stringWithContentsOfURL:kernelURL encoding:NSUTF8StringEncoding error:&error];
    if (!kernelString) {
        kernelString = MEKHVACFilterFragmentShaderString;
    }
    if (!kernelString) {
        return nil;
    }
    return [CIColorKernel kernelWithString:kernelString];
}

+ (void)updateKernelIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (MTLCreateSystemDefaultDevice()) {
#if MEKMETAL_ENABLED
            NSURL *metalURL = nil;
            if (!metalURL) {
                metalURL = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"metallib"];
            }
            NSData *data = [NSData dataWithContentsOfURL:metalURL];
            NSError *error;
            _hvacKernel = [CIColorKernel kernelWithFunctionName:@"mek_main" fromMetalLibraryData:data error:&error];
            if (!_hvacKernel) {
                _hvacKernel = [self readKernelFromBundle];
            }
#else
            _hvacKernel = [self readKernelFromBundle];
#endif
        } else {
            _hvacKernel = [self readKernelFromBundle];
        }
    });
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.class updateKernelIfNeeded];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self.class updateKernelIfNeeded];
    }
    return self;
}


- (CIImage *__nullable)renderImage:(CIImage *)image {
    CGSize size = image.extent.size;
    CGFloat halfWidth = size.width * 0.5;
    CIImage *contentImage = [image imageByCroppingToRect:CGRectMake(halfWidth, 0, halfWidth, size.height)];
    contentImage = [contentImage imageByApplyingTransform:CGAffineTransformMakeTranslation(-halfWidth, 0)];
    CIImage *alphaImage = [image imageByCroppingToRect:CGRectMake(0, 0, halfWidth, size.height)];
    return [self renderContentImage:contentImage alphaImage:alphaImage];
}

- (CIImage *__nullable)renderImage:(CIImage *__nonnull)image maskContent:(MEKHVACMaskContent *__nullable)content frameIndex:(NSInteger)frameIndex {
    if (!content) {
        return [self renderImage:image];
    }
    if (content.rgbFrame.size.width <= 0 || content.rgbFrame.size.height <= 0) {
        return image;
    }
    if (content.alphaFrame.size.width <= 0 || content.alphaFrame.size.height <= 0) {
        return image;
    }
    CGFloat xScale = content.rgbFrame.size.width / content.alphaFrame.size.width;
    CGFloat yScale = content.rgbFrame.size.height / content.alphaFrame.size.height;
    CIImage *contentImage = [image imageByCroppingToRect:content.rgbFrame];
    contentImage = MEKHVACFixCIImageOriginal(contentImage);
    CIImage *alphaImage = [image imageByCroppingToRect:content.alphaFrame];
    alphaImage = [alphaImage imageByApplyingTransform:CGAffineTransformMakeScale(xScale, yScale)];
    alphaImage = MEKHVACFixCIImageOriginal(alphaImage);
    CIImage *bkgImage = [self renderContentImage:contentImage alphaImage:alphaImage];
    MEKHVACMaskFrameItem *item = [content maskItemAtFrameIndex:frameIndex];
    if (!item || item.attachments.count == 0) {
        return bkgImage;
    }
    CIImage *overlayImage = [item compositedImageWithSourceImage:image size:contentImage.extent.size];
    if (!overlayImage) {
        return bkgImage;
    }
    return [overlayImage imageByCompositingOverImage:bkgImage];
}


- (CIImage *__nullable)renderContentImage:(CIImage *__nonnull)contentImage alphaImage:(CIImage *__nonnull)alphaImage {
    
    NSMutableArray *array = [NSMutableArray array];
    if (contentImage) {
        [array addObject:contentImage];
    }
    if (alphaImage) {
        [array addObject:alphaImage];
    }
    if (array.count < 2) {
        return contentImage;
    }
    return [_hvacKernel applyWithExtent:CGRectMake(0, 0, contentImage.extent.size.width, contentImage.extent.size.height) roiCallback:^CGRect(int index, CGRect destRect) {
        return destRect;
    } arguments:array];
}

@end


@implementation MEKHVACMaskFrameItem (MEKCompositeImage)

- (CIImage *__nullable)compositedImageWithSourceImage:(CIImage *__nonnull)sourceImage size:(CGSize)size {
    if (self.attachments.count == 0) {
        return nil;
    }
    BOOL hasResultImage = NO;
    CIImage *resultImage = [[CIImage imageWithColor:CIColor.clearColor] imageByCroppingToRect:CGRectMake(0, 0, size.width, size.height)];
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    
    for (MEKHVACMaskAttachment *attachment in self.attachments) {
        CIImage *maskImage = [sourceImage imageByCroppingToRect:attachment.maskFrame];
        maskImage = MEKHVACFixCIImageOriginal(maskImage);
        maskImage = [maskImage imageByApplyingTransform:CGAffineTransformMakeTranslation(attachment.frame.origin.x, attachment.frame.origin.y)];
        
        CIImage *attachmentImage = [attachment compositedImage];
        attachmentImage = [attachmentImage imageByApplyingTransform:CGAffineTransformMakeTranslation(attachment.frame.origin.x, attachment.frame.origin.y)];
        
        [blendFilter setValue:resultImage forKey:kCIInputBackgroundImageKey];
        [blendFilter setValue:attachmentImage forKey:kCIInputImageKey];
        [blendFilter setValue:maskImage forKey:kCIInputMaskImageKey];
        CIImage *outputImage = blendFilter.outputImage;
        if (outputImage) {
            resultImage = outputImage;
            hasResultImage = YES;
        }
    }
    if (!hasResultImage) {
        return nil;
    }
    return resultImage;
}

@end
