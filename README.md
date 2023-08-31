# 使用 iOS 自带播放器 AVPlayer 播放 VAP 视频

非常感谢 VAP 团队分享透明通道以及遮罩播放的方案, 提供这种思路的人简直就是天才，感谢团队的奉献。

出于个人兴趣，本 Demo 使用 iOS 自带的 AVPlayer + CoreImage 实现了原 VAP 中的功能，增加了音频播放的原生支持，提供给后续想深入了解 VAP 的同学一些参考内容，项目中的一些类或者前缀是从公司项目中扒出来的，目前可能不是最精简的，后续可能会优化。


## 整体思路
AVPlayerItem 在播放的过程中可以指定一个 `AVVideoComposition`，设置完 videoComposition 之后，会在每一帧渲染之前产生回调，并且支持使用 CoreImage 进行处理。

基于此回调，在加上我们解析的 vapc 信息，以及相关 CIImage 处理，我们就可以完成最终的内容渲染。

## 代码说明
整体代码都在目录 HVAC 下，这个表示 Video with Alpha Channel。

### Reader
- MEKHVACMaskContent 遮罩层内容管理类
- MEKHVACMaskFrameItem 每一帧的遮罩信息
- MEKHVACMaskAttachment 每一帧遮罩上的附件信息，包含 zIndex，展示位置，BlendMask 位置等
- MEKHVACMaskAttachmentTexture 遮罩上面的附件内容


Demo 中精简了解析 box 部分，修改为只读取 box 类型 vapc 的 JSON 内容，并解析成 MEKHVACMaskContent 对象。 可以参考 MEKHVACMaskReader + maskContentWithFileURL。
```

@implementation MEKHVACMaskReader

+ (MEKHVACMaskContent *__nullable)maskContentWithFileURL:(NSURL *)fileURL {
    ......
    [fileHandle seekToFileOffset:0];
    
    BOOL hasSuperBox = NO;
    long long offset = 0;
    while (offset < fileLength) {
        [fileHandle seekToFileOffset:offset];
        NSData *data = [fileHandle readDataOfLength:8];
        MEKMP4BoxHeader header = *((MEKMP4BoxHeader *)data.bytes);
        int32_t type =  CFSwapInt32BigToHost(header.type);
        ...
        int32_t length = CFSwapInt32BigToHost(header.length);

        if (type == MEK_FOURCC_TYPE('v', 'a', 'p', 'c')) {
            if (offset + length > fileLength) {
                return nil;
            }
            NSData *jsonData = [fileHandle readDataOfLength:length - 8];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
            if (![jsonDict isKindOfClass:NSDictionary.class]) {
                return nil;
            }
            return [[MEKHVACMaskContent alloc] initWithDictionary:jsonDict];
        }
        
        offset += length;
    }
    return nil;
}

@end

```

### Render
使用 CoreImage 混合各种图层

然后根据 vapc box 中的帧信息 （MEKHVACMaskFrameItem），以及每一帧的附件信息 （MEKHVACMaskAttachment），根据类型生成 CIImage

```
- (CIImage *__nullable)renderImage:(CIImage *__nonnull)image maskContent:(MEKHVACMaskContent *__nullable)content frameIndex:(NSInteger)frameIndex;
```

融合也分为两部分：
- 先融合 rgb 和 alpha 区域，处理为 CIImage
- 把所有的遮罩信息，根据遮罩 mask 合成
- 把背景和遮罩融合，返回最终的 CIImage。

其中使用到了 CoreImage 中的 `CIBlendWithMask`， CISourceOverCompositing 滤镜。 

### Player 

使用 AVPlayer + VideoCompositon

外部使用：
```
MEKHVACEffectPlayerView
- (void)playWithURL:(NSURL *__nullable)url repeatCount:(NSInteger)repeatCount userInfo:(NSDictionary<NSString *, id> *__nullable)userInfo;
```

如果需要设置遮罩内容，则提供 maskContentAttachmentProvider 回调就可以。 









