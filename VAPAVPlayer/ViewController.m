//
//  ViewController.m
//  VAPAVPlayer
//
//  Created by 孙江挺 on 2023/8/31.
//

#import "ViewController.h"
#import "MEKHVACEffectPlayerView.h"
#import "MEKHVACMaskAttachmentTexture+Render.h"

@import AVFAudio;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.brownColor;
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    MEKHVACEffectPlayerView *playerView = [[MEKHVACEffectPlayerView alloc] initWithFrame:self.view.bounds];
    playerView.muted = NO;
    
    // 以下测试也可以支持网络图片，只是懒得测试了。回调的时候使用 uiimage 就可以。
    NSDictionary *imageNames = @{
        @"img1": @"keai",
        @"img2": @"yingyuan"
    };
    
    NSDictionary *textTags = @{
        @"txt1": @"Hello, world",
        @"txt2": @"VAP Is Good"
    };
    playerView.maskContentAttachmentProvider = ^(MEKHVACEffectPlayerView * _Nonnull view, NSDictionary<NSString *,id> * _Nullable userInfo, MEKHVACMaskAttachmentTexture * _Nonnull attachment, MEKHVACMaskAttachmentCompletionBlock  _Nonnull callback) {
        CGSize attachmentSize = CGSizeMake(attachment.width, attachment.height);
        if (attachment.contentType == MEKHVACMaskAttachmentContentTypeImage) {
            // 这里可以等待图片下载
            UIImage *resultImage = nil;
            NSString *imageName = [imageNames valueForKey:attachment.contentTag];
            if (imageName.length > 0) {
                resultImage = [UIImage imageNamed:imageName];
            }
            MTFImageResizeMode mode = (attachment.contentMode == MEKHVACMaskAttachmentContentModeAspectFit) ? MTFImageResizeModeScaleAspectFit2 : MTFImageResizeModeScaleAspectFill;
            
            CIImage *callbackImage = [MEKHVACMaskAttachmentTexture makeImageWithUIImage:resultImage constrainedToSize:attachmentSize resizeMode:mode];
            callback(callbackImage, nil);
        } else {
            NSString *content = [textTags valueForKey:attachment.contentTag] ?: @"Suen";
            CIImage *callbackImage = [MEKHVACMaskAttachmentTexture makeImageWithText:content color:UIColor.yellowColor constrainedToSize:attachmentSize font:[UIFont boldSystemFontOfSize:20] textAlignment:NSTextAlignmentLeft];
            callback(callbackImage, nil);
        }
    };
    
    // 测试数据 vap_video_1/vap_video_2, vap_video_2 有声音
    playerView.effectDidFinishPlaying = ^(MEKBaseEffectPlayerView * _Nonnull view, NSDictionary<NSString *,id> * _Nullable userInfo) {
        NSInteger index = (arc4random() % 2 == 0) ? 1 : 2;
        NSURL *videoURL = [NSBundle.mainBundle URLForResource:[NSString stringWithFormat:@"vap_video_%@", @(index)] withExtension:@"mp4"];
        [view playWithURL:videoURL repeatCount:2 userInfo:nil];
    };
    
    [self.view addSubview:playerView];
    NSURL *videoURL = [NSBundle.mainBundle URLForResource:@"vap_video_1" withExtension:@"mp4"];
    [playerView playWithURL:videoURL repeatCount:2 userInfo:nil];
    
    
}


@end
