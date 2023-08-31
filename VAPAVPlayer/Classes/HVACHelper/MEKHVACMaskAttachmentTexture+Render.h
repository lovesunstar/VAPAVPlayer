//
//  MEKHVACMaskAttachmentTexture+Render.h
//  VAPAVPlayer
//
//  Created by 孙江挺 on 2023/8/31.
//

#import <Foundation/Foundation.h>
#import "UIImage+MTFResize.h"
#import "MEKHVACMaskAttachmentTexture.h"

NS_ASSUME_NONNULL_BEGIN

@class CIImage;

@interface MEKHVACMaskAttachmentTexture (CIImage)

/// 绘制遮罩层的文本。
+ (CIImage *__nullable)makeImageWithText:(NSString *__nullable)text color:(UIColor *__nullable)color constrainedToSize:(CGSize)size font:(UIFont *__nullable)font textAlignment:(NSTextAlignment)textAlignment;

+ (CIImage *__nullable)makeImageWithUIImage:(UIImage *__nonnull)uiImage  constrainedToSize:(CGSize)size resizeMode:(MTFImageResizeMode)mode;

@end



NS_ASSUME_NONNULL_END
