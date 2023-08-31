//
//  MEKHVACMaskAttachmentTexture+Render.m
//  VAPAVPlayer
//
//  Created by 孙江挺 on 2023/8/31.
//

#import "MEKHVACMaskAttachmentTexture+Render.h"
#import <CoreImage/CoreImage.h>

@implementation MEKHVACMaskAttachmentTexture (CIImage)

+ (CIImage *__nullable)makeImageWithText:(NSString *__nullable)text color:(UIColor *__nullable)color constrainedToSize:(CGSize)size font:(UIFont *__nullable)font textAlignment:(NSTextAlignment)textAlignment {
    
    if (text.length == 0 || CGSizeEqualToSize(CGSizeZero, size)) {
        return nil;
    }
    
    font = font ?: [UIFont systemFontOfSize:20];
    color = color ?: UIColor.blackColor;
    
    // 这块保留原 VAP 逻辑，自动缩小字号
    UIFont *designedFont = font;
    CGFloat designedFontSize = font.pointSize;
    
    CGSize stringSize = [text sizeWithAttributes:@{NSFontAttributeName:designedFont}];
    CGFloat fontSize = designedFontSize;
    NSInteger remainExcuteCount = 100;
    while (stringSize.width > size.width && fontSize > 2.0 && remainExcuteCount > 0) {
        fontSize *= 0.9;
        remainExcuteCount -= 1;
        designedFont = [font fontWithSize:fontSize];
        stringSize = [text sizeWithAttributes:@{NSFontAttributeName:designedFont}];
    }
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = textAlignment;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    NSDictionary *attributes = @{
        NSFontAttributeName: designedFont,
        NSParagraphStyleAttributeName:paragraphStyle,
        NSForegroundColorAttributeName:color
    };
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    CGRect textFrame = CGRectMake(0, (size.height - stringSize.height) * 0.5, size.width, stringSize.height);
    [text drawWithRect:textFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (!image || !image.CGImage) {
        return nil;
    }
    return [CIImage imageWithCGImage:image.CGImage];
}


+ (CIImage *__nullable)makeImageWithUIImage:(UIImage *__nonnull)uiImage  constrainedToSize:(CGSize)size resizeMode:(MTFImageResizeMode)mode {
    if (!uiImage) {
        return nil;
    }
    uiImage = [uiImage mtf_imageConstrainedToSize:size mode:mode];
    if (!uiImage.CGImage) {
        return nil;
    }
    return [CIImage imageWithCGImage:uiImage.CGImage];
}

@end
