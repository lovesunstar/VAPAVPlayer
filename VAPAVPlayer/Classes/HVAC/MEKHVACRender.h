//
//  MEKHVACRender.h
//
//  Created by 江挺孙 on 2020/7/2.
//  Copyright © 2020 孙江挺. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "MEKHVACMaskContent.h"

NS_ASSUME_NONNULL_BEGIN
/// Horizontal Video with Alpha Channel, 为了支持 Alpha 通道，实现左右布局图片，左边表示色彩，右边表示透明度
@interface MEKHVACRender : CIFilter

- (CIImage *__nullable)renderImage:(CIImage *)image;

/// 整体融合步骤：
/// 1. 根据 rgbFrame 和 alphaFrame，先融合出背景图。使用 HVACFilter。
/// 2. 获取这一帧的遮罩内容和遮罩区域
/// 3. 把遮罩内容和遮罩区域进行 AlphaBlend
/// 4. 添加到 步骤1 中生成的图片上。
/// 2,3,4 在一次融合中可能出现多次，比如一帧中又多个融合的内容。2,3,4 使用 CIBlendWithMask Filter。
- (CIImage *__nullable)renderImage:(CIImage *__nonnull)image maskContent:(MEKHVACMaskContent *__nullable)content frameIndex:(NSInteger)frameIndex;

@end


@interface MEKHVACMaskFrameItem (MEKCompositeImage)

/// 把遮罩层的图像混合
- (CIImage *__nullable)compositedImageWithSourceImage:(CIImage *__nonnull)sourceImage size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
