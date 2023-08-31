//
//  MEKBaseEffectPlayerView.m
//  MEKEffectPlayer
//
//  Created by 孙江挺 on 2022/3/18.
//

#import "MEKBaseEffectPlayerView.h"

@interface MEKBaseEffectPlayerView ()

@property (nonatomic, strong) MEKEffectPlayerCallbackItem *callbackItem;
@property (nonatomic, strong) NSTimer *loadTimeoutTimer;

@property (nonatomic) BOOL isStopping;

@end

@implementation MEKBaseEffectPlayerView

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_loadTimeoutTimer invalidate];
    _loadTimeoutTimer = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self loadSubviews];
    }
    return self;
}

- (void)loadSubviews {
    self.userInteractionEnabled = NO;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)playWithURL:(NSURL *__nullable)url repeatCount:(NSInteger)repeatCount userInfo:(NSDictionary<NSString *, id> *)userInfo {
    
    _isStopping = NO;
    
    if (!url) {
        [self stop];
    }
    MEKEffectPlayerCallbackItem *item = [[MEKEffectPlayerCallbackItem alloc] initWithURL:url];
    item.repeatCount = repeatCount;
    item.playCount = 0;
    item.failedCount = 0;
    item.userInfo = userInfo;
    item.hasCallbackStart = NO;
    item.hasCallbackFinish = NO;
    item.repeatCount = repeatCount;
    self.callbackItem = item;
    [self playWithURL:url item:item];
}

- (void)handlePlayWithURL:(NSURL *)url repeatCount:(NSInteger)repeatCount {
    
}

- (void)playWithURL:(NSURL *)url item:(MEKEffectPlayerCallbackItem *)item {
    [self handlePlayWithURL:url repeatCount:item.repeatCount];
}

- (NSTimeInterval)duration {
    return 0.0;
}

- (NSDictionary<NSString *,id> *)userInfo {
    return self.callbackItem.userInfo;
}

- (void)stop {
    if (_isStopping) {
        return;
    }
    _isStopping = YES;
    [self invalidateLoadTimer];
    if (self.callbackItem) {
        if (!self.callbackItem.hasCallbackFinish && self.callbackItem.hasCallbackStart) {
            // Callback Finish
            [self _handleDidFinishPlayingForceFinish:YES];
        }
    }
    self.callbackItem = nil;
    _isStopping = NO;
}

- (void)invokeDidReady {
    if (!self.callbackItem) {
        return;
    }
    if (!self.callbackItem.hasCallbackReady) {
        if (self.effectDidReadyToPlay) {
            self.effectDidReadyToPlay(self, self.callbackItem.userInfo);
        }
        self.callbackItem.hasCallbackReady = YES;
    }
}

- (void)invokeDidStartPlaying {
    [self invalidateLoadTimer];
    if (!self.callbackItem) {
        return;
    }
    self.callbackItem.failedCount = 0;
    if (!self.callbackItem.hasCallbackStart) {
        if (self.effectDidStartPlaying) {
            self.effectDidStartPlaying(self, self.callbackItem.userInfo);
        }
        self.callbackItem.hasCallbackStart = YES;
    }
}

- (void)_handleDidFinishPlayingForceFinish:(BOOL)forceFinish {
    
    [self invalidateLoadTimer];
    if (!self.callbackItem) {
        return;
    }
    self.callbackItem.failedCount = 0;
    
    self.callbackItem.playCount += 1;
    
    NSInteger repeatCount = self.callbackItem.repeatCount;
    BOOL shouldStop = repeatCount >= 0 && (self.callbackItem.playCount > repeatCount);
    if (!(forceFinish || shouldStop)) {
        [self replay];
        return;
    }
    if (!self.callbackItem.hasCallbackFinish) {
        self.callbackItem.hasCallbackFinish = YES;
        if (self.effectDidFinishPlaying) {
            self.effectDidFinishPlaying(self, self.callbackItem.userInfo);
        }
    }
}

- (void)invokeDidFinishPlayingForced:(BOOL)forced {
    [self _handleDidFinishPlayingForceFinish:forced];
}

- (void)invokeDidFailToPlay:(NSError *__nullable)error {
    [self invalidateLoadTimer];
    if (!self.callbackItem) {
        return;
    }
    if (self.callbackItem.failedCount < 5) {
        self.callbackItem.failedCount += 1;
        [self playWithURL:self.callbackItem.url item:self.callbackItem];
    } else {
        [self _handleDidFinishPlayingForceFinish:YES];
        if (self.effectDidFailToPlay) {
            self.effectDidFailToPlay(self, self.callbackItem.userInfo, error);
        }
        self.callbackItem = nil;
    }
}

- (void)replay {
    
}

- (void)pause {
    
}

- (void)resume {
    
}

/// 如果 5s 内没有开始播放，并且播放器也没有给回调，则认为播放失败了，直接调用 Fail To Play
- (void)startLoadTimer {
    [_loadTimeoutTimer invalidate];
    __weak MEKBaseEffectPlayerView *weakSelf = self;
    _loadTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
        MEKBaseEffectPlayerView *strongSelf = weakSelf;
        [strongSelf invokeDidFailToPlay:MEKCreateEffectPlayerError(1, @{@"reason": @"timedout"})];
    }];
}

- (void)invalidateLoadTimer {
    [_loadTimeoutTimer invalidate];
    _loadTimeoutTimer = nil;
}

- (void)handleEnterForeground {
    if (self.callbackItem) {
        [self resume];
    }
}

- (void)handleEnterBackground {
    if (self.callbackItem) {
        [self pause];
    }
}

- (void)invokeDidPlayAtTime:(NSTimeInterval)time {
    _currentTime = time;
    if (!self.callbackItem) {
        return;
    }
    if (!_shouldNotifyPlayTime) {
        return;
    }
    NSTimeInterval duration = self.duration;
    if (self.effectDidPlayAtTime) {
        self.effectDidPlayAtTime(self, self.callbackItem.userInfo, time, duration);
    }
}

@end

const NSString *__nonnull MEKEffectPlayerErrorDomain = @"MEKEffectPlayerErrorDomain";

NSError *MEKCreateEffectPlayerError(NSInteger code, NSDictionary *__nullable userInfo) {
    return [NSError errorWithDomain:(NSErrorDomain)MEKEffectPlayerErrorDomain code:code userInfo:userInfo];
}
