//
//  UIImage+MTFResize.h
//  Fundamental
//
//  Created by 孙江挺 on 2018/7/5.
//  Copyright © 2018年 M&E Times. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 图片拉伸方式
/// 
typedef NS_ENUM(NSUInteger, MTFImageResizeMode) {
    /// 拉伸填充
    MTFImageResizeModeScaleToFill,
    /// 长边对齐, 当原图尺寸小于目标尺寸时，不压缩图片；
    MTFImageResizeModeScaleAspectFit,
    /// 短边对齐，长边裁切。
    MTFImageResizeModeScaleAspectFill,
    /// 注意这个和 ScaleAspectFit 的区别，这个会长边对其，但是会按照指定大小返回图片，其余部分保留透明
    MTFImageResizeModeScaleAspectFit2,
    /// 长边对其，但是等比拉升到目标尺寸。 这个和上面的区别是 当图片比较小的时候也会强制拉大
    MTFImageResizeModeScaleAspectStretch
};
/// 缩放图片
@interface UIImage (MTFResize)

/**
 * 把图片缩放到 size 以内，内部会纠正图片方向, 默认图片不会变形。 如果 size > 图片大小，则只纠正方向，不做压缩
 *
 * @param size 图片限制的最大宽高，图片最终肯定在这个 size 内
 * @returns 返回处理之后的图片
 */
- (nullable UIImage *)mtf_imageConstrainedToSize:(CGSize)size NS_SWIFT_NAME(resize(constrainedTo:));

/**
 * 把图片缩放到 size 以内，内部会纠正图片方向
 *
 * @param size 图片限制的最大宽高，图片最终肯定在这个 size 内
 * @param mode 当尺寸不一致时，图片的缩放方式
 * @returns 返回处理之后的图片
 */
- (nullable UIImage *)mtf_imageConstrainedToSize:(CGSize)size mode:(MTFImageResizeMode)mode NS_SWIFT_NAME(resize(constrainedTo:mode:));

/**
 * 把图片缩放到 size 以内，内部会纠正图片方向
 *
 * @param size 图片限制的最大宽高，图片最终肯定在这个 size 内
 * @param mode 当尺寸不一致时，图片的缩放方式
 * @param backgroundColor 默认填充背景色
 * @returns 返回处理之后的图片
 */
- (nullable UIImage *)mtf_imageConstrainedToSize:(CGSize)size mode:(MTFImageResizeMode)mode backgroundColor:(UIColor *__nullable)backgroundColor NS_SWIFT_NAME(resize(constrainedTo:mode:backgroundColor:));


/**
 * 截取图片中的某片区域
 *
 * @param rect 图片区域
 * @returns 返回处理之后的图片
 */
- (nullable UIImage *)mtf_subimageInRect:(CGRect)rect NS_SWIFT_NAME(subimage(rect:));

@end
