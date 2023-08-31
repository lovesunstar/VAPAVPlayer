//
//  MEKHVACMaskContent.m
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/30.
//

#import "MEKHVACMaskContent.h"
#import "MEKHVACMaskUtilities.h"
#import <UIKit/UIKit.h>

@interface MEKHVACMaskAttachment()

@property (nonatomic, readonly) NSInteger zIndex;
@property (nonatomic, readonly, nonnull, copy) NSString *attachmentID;
@property (nonatomic, readonly, nonnull) MEKHVACMaskAttachmentTexture *texture;

@end

@implementation MEKHVACMaskAttachment

- (instancetype)initWithDictionary:(NSDictionary *)dict naturalSize:(CGSize)naturalSize videoSize:(CGSize)videoSize textures:(NSDictionary<NSString *, MEKHVACMaskAttachmentTexture *> *)textures {
    NSString *attachmentID = nil;
    id idValue = dict[@"srcId"];
    if ([idValue isKindOfClass:NSString.class]) {
        attachmentID = [idValue copy];
    } else {
        attachmentID = [NSString stringWithFormat:@"%@", idValue];
    }
    if (attachmentID.length == 0) {
        return nil;
    }
    MEKHVACMaskAttachmentTexture *texture = [textures valueForKey:attachmentID];
    if (![texture isKindOfClass:MEKHVACMaskAttachmentTexture.class]) {
        return nil;
    }
    self = [super init];
    if (self) {
        _zIndex = MEKHVACMaskParseInteger(dict[@"z"]);
        _attachmentID = [attachmentID copy];
        CGRect frame = MEKHVACMaskParseFrame(dict[@"frame"]);
        frame.origin.y = videoSize.height - CGRectGetMaxY(frame);
        _frame = frame;
        
        CGRect maskFrame = MEKHVACMaskParseFrame(dict[@"mFrame"]);
        maskFrame.origin.y = naturalSize.height - CGRectGetMaxY(maskFrame);
        _maskFrame = maskFrame;
        _texture = texture;
    }
    return self;
}

- (CIImage *)compositedImage {
    return [_texture compositedImage];
//    return [[CIImage imageWithColor:CIColor.redColor] imageByCroppingToRect:CGRectMake(0, 0, _frame.size.width, _frame.size.height)];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Src: %@; Frame: %@", _attachmentID, NSStringFromCGRect(_frame)];
}

@end

@interface MEKHVACMaskFrameItem ()

@property (nonatomic, readonly) NSInteger frameIndex;

@end

@implementation MEKHVACMaskFrameItem

- (instancetype)initWithDictionary:(NSDictionary *)dict naturalSize:(CGSize)naturalSize videoSize:(CGSize)videoSize textures:(NSDictionary<NSString *, MEKHVACMaskAttachmentTexture *> *)textures {
    if (![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSArray<NSDictionary *> *objects = [dict valueForKey:@"obj"];
    if (![objects isKindOfClass:NSArray.class]) {
        return nil;
    }
    self = [super init];
    if (self) {
        _frameIndex = MEKHVACMaskParseInteger(dict[@"i"]);
        NSMutableArray<MEKHVACMaskAttachment *> *attachments = [NSMutableArray arrayWithCapacity:objects.count];
        for (NSDictionary *obj in objects) {
            if (![obj isKindOfClass:NSDictionary.class]) {
                continue;
            }
            MEKHVACMaskAttachment *attachment = [[MEKHVACMaskAttachment alloc] initWithDictionary:obj naturalSize:naturalSize videoSize:videoSize textures:textures];
            if (!attachment) {
                continue;
            }
            [attachments addObject:attachment];
        }
        if (attachments.count == 0) {
            self = nil;
            return nil;
        }
        _attachments = [[NSArray arrayWithArray:attachments] sortedArrayUsingComparator:^NSComparisonResult(MEKHVACMaskAttachment  *obj1, MEKHVACMaskAttachment  *obj2) {
            return [@(obj1.zIndex) compare:@(obj2.zIndex)];
        }];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@; %@", @(_frameIndex), self.attachments];
}

@end

@interface MEKHVACMaskContent ()

@property (nonatomic) CGRect rgbFrame;
@property (nonatomic) CGRect alphaFrame;

@property (nonatomic, copy, readonly, nullable) NSDictionary<NSNumber *, MEKHVACMaskFrameItem *> *maskItems;

@end

@implementation MEKHVACMaskContent

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSDictionary *info = [dict valueForKey:@"info"];
    if (![info isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    CGRect rgbFrame = MEKHVACMaskParseFrame(info[@"rgbFrame"]);
    CGRect alphaFrame = MEKHVACMaskParseFrame(info[@"aFrame"]);
    CGFloat naturalWidth = MEKHVACMaskParseFloat(info[@"videoW"]);
    CGFloat naturalHeight = MEKHVACMaskParseFloat(info[@"videoH"]);
    CGFloat videoWidth = MEKHVACMaskParseFloat(info[@"w"]);
    CGFloat videoHeight = MEKHVACMaskParseFloat(info[@"h"]);
    if (CGRectIsEmpty(rgbFrame) || naturalWidth <= 0 || naturalHeight <= 0) {
        return nil;
    }
    self = [super init];
    if (self) {
        rgbFrame.origin.y = naturalHeight - CGRectGetMaxY(rgbFrame);
        self.rgbFrame = rgbFrame;

        alphaFrame.origin.y = naturalHeight - CGRectGetMaxY(alphaFrame);
        self.alphaFrame = alphaFrame;
        
        _fps = MEKHVACMaskParseInteger(info[@"fps"]);
        _naturalSize = CGSizeMake(naturalWidth, naturalHeight);
        if (videoWidth > 0 && videoHeight > 0) {
            _videoSize = CGSizeMake(videoWidth, videoHeight);
        } else {
            _videoSize = rgbFrame.size;
        }
        
        
        NSArray<NSDictionary *> *srcs = [dict valueForKey:@"src"];
        if ([srcs isKindOfClass:NSArray.class]) {
            NSMutableDictionary<NSString *, MEKHVACMaskAttachmentTexture *> *textures = [NSMutableDictionary dictionaryWithCapacity:srcs.count];
            for (NSDictionary *src in srcs) {
                if (![src isKindOfClass:NSDictionary.class]) {
                    continue;
                }
                MEKHVACMaskAttachmentTexture *obj = [[MEKHVACMaskAttachmentTexture alloc] initWithDictionary:src];
                if (!obj) {
                    continue;
                }
                [textures setValue:obj forKey:obj.textureID];
            }
            _textures = [NSDictionary dictionaryWithDictionary:textures];
        } else {
            _textures = @{};
        }
        
        NSArray<NSDictionary *> *objects = [dict valueForKey:@"frame"];
        if ([objects isKindOfClass:NSArray.class]) {
            NSMutableDictionary<NSNumber *, MEKHVACMaskFrameItem *> *maskItems = [NSMutableDictionary dictionaryWithCapacity:objects.count];
            for (NSDictionary *obj in objects) {
                if (![obj isKindOfClass:NSDictionary.class]) {
                    continue;
                }
                MEKHVACMaskFrameItem *frame = [[MEKHVACMaskFrameItem alloc] initWithDictionary:obj naturalSize:_naturalSize videoSize:_videoSize textures:_textures];
                if (!frame) {
                    continue;
                }
                [maskItems setObject:frame forKey:@(frame.frameIndex)];
            }
            _maskItems = [NSDictionary dictionaryWithDictionary:maskItems];
        } else {
            _maskItems = @{};
        }
        
        
    }
    return self;
}

- (MEKHVACMaskFrameItem *__nullable)maskItemAtFrameIndex:(NSInteger)frameIndex {
    return _maskItems[@(frameIndex)];
}

@end
