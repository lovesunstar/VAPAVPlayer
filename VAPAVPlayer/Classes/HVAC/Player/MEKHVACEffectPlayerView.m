//
//  MEKHVACEffectPlayerView.m
//  Karaoke
//
//  Created by 孙江挺 on 2022/3/17.
//  Copyright © 2022 M&E Times. All rights reserved.
//

#import "MEKHVACEffectPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "MEKHVACRender.h"
#import "MEKHVACMaskReader.h"

@interface MEKHVACEffectPlayerView()

@property (nonatomic) CGSize viewSize;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) NSURL *playURL;
@property (nonatomic, strong) MEKHVACRender *render;

@property (nonatomic) id timeObserver;

@property (nonatomic) NSTimeInterval effectDuration;

@property (nonatomic) CGSize effectVideoSize;

@property (nonatomic) BOOL hasCallbackDidStart;
@end

@implementation MEKHVACEffectPlayerView

- (void)dealloc {
    [self.player removeObserver:self forKeyPath:@"status"];
    [self removePlayerTimeObserver];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    _player = nil;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _viewSize = frame.size;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    _player.muted = muted;
}

- (void)loadSubviews {
    [super loadSubviews];
    _viewSize = self.frame.size;
    self.render = [[MEKHVACRender alloc] init];
    self.player = [[AVPlayer alloc] init];
    self.player.muted = _muted;
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.player = self.player;
    self.playerLayer.contentsGravity = kCAGravityResizeAspect;
    
    [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    self.playerLayer.pixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [self.layer insertSublayer:self.playerLayer atIndex:0];
        
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handlePlayerItemDidEndNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handlePlayerItemDidFailToEndNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    _effectDuration = 0;
}

- (void)handlePlayWithURL:(NSURL *)url repeatCount:(NSInteger)repeatCount {
    _hasCallbackDidStart = NO;
    if (!url) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.playerItem = nil;
        self.playURL = nil;
        _effectDuration = 0;
        [self removePlayerTimeObserver];
        return;
    }
    AVAsset *asset = [AVURLAsset assetWithURL:url];
    if (!asset) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.playerItem = nil;
        self.playURL = nil;
        _effectDuration = 0;
        [self invokeDidFailToPlay:MEKCreateEffectPlayerError(2, @{@"reason": @"asset create failed"})];
        [self removePlayerTimeObserver];
        return;
    }
    
    MEKHVACMaskContent *maskContent = [MEKHVACMaskReader maskContentWithFileURL:url];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    self.playerItem = playerItem;
    self.playURL = url;
    _effectDuration = CMTimeGetSeconds(asset.duration);
    __weak MEKHVACEffectPlayerView *weakSelf = self;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
//        NSDate *start = NSDate.date;
        CIImage *processedImage = nil;
        if (maskContent) {
            NSInteger frameIndex = (NSInteger)round(CMTimeGetSeconds(request.compositionTime) * maskContent.fps);
            processedImage = [weakSelf.render renderImage:request.sourceImage maskContent:maskContent frameIndex:frameIndex];
        } else {
            processedImage = [weakSelf.render renderImage:request.sourceImage];
        }
//        NSLog(@"---> %@", @([NSDate.date timeIntervalSinceDate:start] * 1000));
        if (processedImage) {
            [request finishWithImage:processedImage context:nil];
        } else {
            NSError *err = [[NSError alloc] init];
            [request finishWithError:err];
        }
        if (!weakSelf.hasCallbackDidStart) {
            MEKHVACEffectPlayerView *strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!strongSelf.hasCallbackDidStart) {
                    [strongSelf invokeDidStartPlaying];
                }
                strongSelf.hasCallbackDidStart = YES;
            });
        }
    }];
    CGSize videoSize = CGSizeZero;
    if (maskContent) {
        videoSize = maskContent.videoSize;
    } else {
        CGSize size = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject.naturalSize;
        videoSize = CGSizeMake(size.width * 0.5, size.height);
    }
    videoComposition.renderSize = videoSize;
    playerItem.videoComposition = videoComposition;
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    
    if (maskContent && maskContent.textures.count > 0 && self.maskContentAttachmentProvider) {
        dispatch_group_t group = dispatch_group_create();
        [maskContent.textures enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MEKHVACMaskAttachmentTexture * _Nonnull obj, BOOL * _Nonnull stop) {
            if (self.maskContentAttachmentProvider) {
                __weak MEKHVACEffectPlayerView *weakSelf = self;
                
                __block BOOL hasCallback = NO;
                MEKHVACMaskAttachmentCompletionBlock callback = ^(CIImage *__nullable image, NSError * __nullable error){
                    MEKHVACEffectPlayerView *strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }
                    obj.compositedImage = image;
                    if (!hasCallback) {
                        dispatch_group_leave(group);
                    }
                    hasCallback = YES;
                };
                dispatch_group_enter(group);
                self.maskContentAttachmentProvider(self, self.userInfo, obj, callback);
            }
        }];
        __weak MEKHVACEffectPlayerView *weakSelf = self;
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            MEKHVACEffectPlayerView *strongSelf = weakSelf;
            [strongSelf.player play];
        });
    } else {
        [_player play];
    }
    
    _effectVideoSize = videoComposition.renderSize;
    if (self.shouldNotifyPlayTime) {
        [self addPlayerTimeObserver];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"] && object == self.player) {
        AVPlayerStatus status = self.player.status;
        if (status == AVPlayerStatusReadyToPlay) {
            if (NSThread.isMainThread) {
                [self invokeDidReady];
            } else {
                __weak MEKHVACEffectPlayerView *weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf invokeDidReady];
                });
            }
        }
    }
}

- (CGSize)videoSize {
    return _effectVideoSize;
}

- (void)setShouldNotifyPlayTime:(BOOL)shouldNotifyPlayTime {
    [super setShouldNotifyPlayTime:shouldNotifyPlayTime];
    if (shouldNotifyPlayTime) {
        [self addPlayerTimeObserver];
    } else {
        [self removePlayerTimeObserver];
    }
}

- (void)removePlayerTimeObserver {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

- (void)addPlayerTimeObserver {
    if (self.timeObserver) {
        return;
    }
    __weak MEKHVACEffectPlayerView *weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        MEKHVACEffectPlayerView *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf invokeDidPlayAtTime:CMTimeGetSeconds(time)];
    }];
}

- (void)stop {
    _effectDuration = 0;
    if (self.playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.playerItem = nil;
        self.playURL = nil;
    }
    [self removePlayerTimeObserver];
    [super stop];
}

- (NSTimeInterval)currentTime {
    if (self.playerItem) {
        return CMTimeGetSeconds([self.player currentTime]);
    }
    return 0;
}

- (NSTimeInterval)duration {
    if (self.playerItem) {
        return _effectDuration;
    }
    return 0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

- (void)replay {
    [super replay];
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)handlePlayerItemDidEndNotification:(NSNotification *)notification {
    if (notification.object != self.playerItem) {
        return;
    }
    if (NSThread.isMainThread) {
        [self invokeDidFinishPlayingForced:NO];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self invokeDidFinishPlayingForced:NO];
        });
    }
}

- (void)handlePlayerItemDidFailToEndNotification:(NSNotification *)notification {
    if (notification.object != self.playerItem) {
        return;
    }
    NSDictionary *userInfo = self.playerItem.error.userInfo;
    if (NSThread.isMainThread) {
        [self invokeDidFailToPlay:MEKCreateEffectPlayerError(3, userInfo)];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self invokeDidFailToPlay:MEKCreateEffectPlayerError(3, userInfo)];
        });
    }
}

- (void)resume {
    if (self.playerItem) {
        [self.player play];
    }
}

- (void)pause {
    [super pause];
    if (self.playerItem) {
        [self.player pause];
    }
}

@end
