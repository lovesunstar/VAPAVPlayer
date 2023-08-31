//
//  MEKBaseEffectPlayerView.h
//  
//  特效播放器基类
//  Created by 孙江挺 on 2022/3/18.
//

#import <UIKit/UIKit.h>
#import "MEKEffectPlayerCallbackItem.h"

NS_ASSUME_NONNULL_BEGIN

/// 特效播放器基类
@interface MEKBaseEffectPlayerView : UIView

@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval currentTime;

@property (nonatomic, readonly) CGSize videoSize;

/// 是否允许实时播放进度回调
@property (nonatomic) BOOL shouldNotifyPlayTime;

@property (nonatomic, copy, nullable, readonly) NSDictionary<NSString *, id> *userInfo;

/// 特效即将播放回调. userInfo 为 play 时传入的
@property (nonatomic, strong, nullable) void (^ effectDidReadyToPlay)(MEKBaseEffectPlayerView *__nonnull view, NSDictionary<NSString *, id> *__nullable userInfo);

/// 特效即将播放回调. userInfo 为 play 时传入的
@property (nonatomic, strong, nullable) void (^ effectDidStartPlaying)(MEKBaseEffectPlayerView *__nonnull view, NSDictionary<NSString *, id> *__nullable userInfo);

/// 特效结束播放回调. userInfo 为 play 传入的
@property (nonatomic, strong, nullable) void (^ effectDidFinishPlaying)(MEKBaseEffectPlayerView *__nonnull view, NSDictionary<NSString *, id> *__nullable userInfo);

/// 播放进度回调
@property (nonatomic, strong, nullable) void (^ effectDidPlayAtTime)(MEKBaseEffectPlayerView *__nonnull view, NSDictionary<NSString *, id> *__nullable userInfo, double time, double duration);

/// 播放失败回调
@property (nonatomic, strong, nullable) void (^ effectDidFailToPlay)(MEKBaseEffectPlayerView *__nonnull view, NSDictionary<NSString *, id> *__nullable userInfo, NSError *__nullable error);

/// 必须调用 super
- (void)loadSubviews;

/// 播放特效, 子类禁止重写. Final
- (void)playWithURL:(NSURL *__nullable)url repeatCount:(NSInteger)repeatCount userInfo:(NSDictionary<NSString *, id> *__nullable)userInfo;

/// 真实去播放特效，外部禁止直接调用。子类需要重写这个方法，并且在内部做播放逻辑
- (void)handlePlayWithURL:(NSURL *)url repeatCount:(NSInteger)repeatCount;

/// 停止播放，必须调用 super
- (void)stop;

/// 当 Repeat 是自动调用，外部禁止调用
- (void)replay;

/// 外部禁止调用， 子类需要重写处理前后台切换
- (void)pause;
/// 外部禁止调用， 子类需要重写处理前后台切换
- (void)resume;

/// 外部禁止调用，子类
- (void)invokeDidReady;
- (void)invokeDidStartPlaying;
- (void)invokeDidFinishPlayingForced:(BOOL)forced;
- (void)invokeDidFailToPlay:(NSError *__nullable)error;

- (void)invokeDidPlayAtTime:(NSTimeInterval)time;

@end

extern const NSString *__nonnull MEKEffectPlayerErrorDomain;

extern NSError *MEKCreateEffectPlayerError(NSInteger code, NSDictionary *__nullable userInfo);

NS_ASSUME_NONNULL_END
