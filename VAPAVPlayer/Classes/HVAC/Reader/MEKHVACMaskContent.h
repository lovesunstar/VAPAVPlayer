//
//  MEKHVACMaskContent.h
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/30.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "MEKHVACMaskAttachmentTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// 视频遮罩层附件
@interface MEKHVACMaskAttachment : NSObject

/// 左下角为原点，相对于视频 rgb 区域
@property (nonatomic, readonly) CGRect frame;
/// 左下角为原点，相对于 整个视频
@property (nonatomic, readonly) CGRect maskFrame;

/// 需要合并成 CIImage，用于做融合处理
- (CIImage *)compositedImage;

@end

/// 某一帧上面的遮罩层信息
@interface MEKHVACMaskFrameItem: NSObject

/// 这一帧的遮罩层附件，这个会按照 zIndex 排好序。
@property (nonatomic, readonly, nonnull) NSArray<MEKHVACMaskAttachment *> *attachments;

@end

/// 读取视频中的 VAP Mask 配置信息， 'vapc' box 解析
/// VAP 视频中，包含 rgb 区域，alpha 通道区域，mask 区域。
@interface MEKHVACMaskContent : NSObject

/// 视频 rgb 区域
@property (nonatomic, readonly) CGRect rgbFrame;
/// 视频 alpha 区域
@property (nonatomic, readonly) CGRect alphaFrame;

/// rgb 区域尺寸, 这个为合成后的视频尺寸。
@property (nonatomic, readonly) CGSize videoSize;

/// 原始视频尺寸，包含 alpha 区域
@property (nonatomic, readonly) CGSize naturalSize;

/// 视频帧率
@property (nonatomic, readonly) NSInteger fps;

/// 遮罩层的纹理。
@property (nonatomic, readonly, copy, nullable) NSDictionary<NSString *, MEKHVACMaskAttachmentTexture *> *textures;

- (instancetype __nullable)initWithDictionary:(NSDictionary *__nonnull)dict;

/// 获取某一帧的遮罩内容
- (MEKHVACMaskFrameItem *__nullable)maskItemAtFrameIndex:(NSInteger)frameIndex NS_SWIFT_NAME(maskItem(at:));

@end

NS_ASSUME_NONNULL_END
