//
//  MEKHVACEffectPlayerView.h
//  Karaoke
//
//  Created by 孙江挺 on 2022/3/17.
//  Copyright © 2022 M&E Times. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MEKBaseEffectPlayerView.h"
#import "MEKHVACMaskContent.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MEKHVACMaskAttachmentCompletionBlock)(CIImage *__nullable image, NSError * __nullable error);

@interface MEKHVACEffectPlayerView : MEKBaseEffectPlayerView

@property (nonatomic, getter=isMuted) BOOL muted;

/// 以下内容可能在子线程执行。 callback 在子线程调用也可以。
@property (nonatomic, strong, nullable) void (^ maskContentAttachmentProvider)(MEKHVACEffectPlayerView *__nonnull view, NSDictionary<NSString *, id> *__nullable userInfo, MEKHVACMaskAttachmentTexture *__nonnull attachment, MEKHVACMaskAttachmentCompletionBlock __nonnull callback);

@end

NS_ASSUME_NONNULL_END
