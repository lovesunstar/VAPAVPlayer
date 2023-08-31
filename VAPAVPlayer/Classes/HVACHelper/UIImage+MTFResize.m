//
//  UIImage+MTFResize.m
//  Fundamental
//
//  Created by 孙江挺 on 2018/7/5.
//  Copyright © 2018年 M&E Times. All rights reserved.
//

#import "UIImage+MTFResize.h"

@implementation UIImage (MTFResize)

// imageSize {100,100} size{200, 50} widthRate = 0.5, heightRate = 2
// imageSize {100,100} size{200, 100} widthRate = 0.5 heightRate = 1
- (UIImage *)mtf_imageConstrainedToSize:(CGSize)size {
    return [self mtf_imageConstrainedToSize:size mode:MTFImageResizeModeScaleAspectFit];
}

- (UIImage *)mtf_imageConstrainedToSize:(CGSize)size mode:(MTFImageResizeMode)mode {
    return [self mtf_imageConstrainedToSize:size mode:mode backgroundColor:nil];
}

/// 按照 mode 修改图片尺寸
- (nullable UIImage *)mtf_imageConstrainedToSize:(CGSize)size mode:(MTFImageResizeMode)mode backgroundColor:(UIColor *__nullable)color {
    UIImage *image = self;
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = image.size;
    if (!imageRef || (size.width == 0 && size.height == 0) || imageSize.height == 0) {
        return nil;
    }
    CGFloat width = 0, height = 0;
    // 如果图片大小再 constrainedSize 之内的话， 并且模式不需要拉伸，则不需要对图片做处理。
    // 首先确定实际的image的大小, 先保证比例，然后找到和constrained比较接近的，计算出实际需要的imageSize。
    CGFloat widthRate = imageSize.width / size.width, heightRate = imageSize.height / size.height;
    if (size.width >= imageSize.width && size.height >= imageSize.height && mode == MTFImageResizeModeScaleAspectFit) {
        width = imageSize.width;
        height = imageSize.height;
    } else {
        if (mode == MTFImageResizeModeScaleAspectFill) {
            if (widthRate < heightRate) {
                width = size.width;
                height = imageSize.height / widthRate;
            } else {
                height = size.height;
                width = imageSize.width / heightRate;
            }
        } else if (mode == MTFImageResizeModeScaleAspectFit2 || mode == MTFImageResizeModeScaleAspectFit || mode == MTFImageResizeModeScaleAspectStretch) {
            if (widthRate < heightRate) {
                height = size.height;
                width = imageSize.width / heightRate;
            } else {
                width = size.width;
                height = imageSize.height / widthRate;
            }
        } else {
           width = size.width;
           height = size.height;
        }
    }
    CGSize newSize = CGSizeMake(roundf(width), roundf(height));
    CGSize contextSize;
    if (mode == MTFImageResizeModeScaleAspectFit2 || mode == MTFImageResizeModeScaleAspectFill) {
        contextSize = size;
    } else {
        contextSize = newSize;
    }
    UIGraphicsBeginImageContextWithOptions(contextSize, NO, MAX(image.scale, 1));
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(contextRef);
    CGColorRef cgColor = color.CGColor;
    if (cgColor) {
        CGColorSpaceRef colorSpace = CGColorGetColorSpace(cgColor);
        CGContextSetFillColorSpace(contextRef, colorSpace);
        const CGFloat *components = CGColorGetComponents(cgColor);
        CGContextSetFillColor(contextRef, components);
        CGContextFillRect(contextRef, CGRectMake(0, 0, contextSize.width, contextSize.height));
    }
    if (mode == MTFImageResizeModeScaleAspectFit2 || mode == MTFImageResizeModeScaleAspectFill) {
        [image drawInRect:CGRectMake((size.width - newSize.width) * 0.5, (size.height - newSize.height) * 0.5, newSize.width, newSize.height)];
    } else {
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }
    UIGraphicsPopContext();
    // And now we just create a new UIImage from the drawing context
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

- (nullable UIImage *)mtf_subimageInRect:(CGRect)rect {
    if (!self.CGImage) {
        return nil;
    }
    CGRect cropRect = CGRectMake(rect.origin.x * self.scale, rect.origin.y * self.scale, rect.size.width * self.scale, rect.size.height * self.scale);
    CGImageRef newImageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    if (!newImageRef) {
        return nil;
    }
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(newImageRef);
    return newImage;
}

@end

