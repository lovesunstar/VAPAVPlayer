//
//  MEKHVACMaskAttachmentTexture.m
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/30.
//

#import "MEKHVACMaskAttachmentTexture.h"
#import "MEKHVACMaskUtilities.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>

@interface MEKHVACMaskAttachmentTexture ()

@property (nonatomic, strong) NSLock *lock;

@end

@implementation MEKHVACMaskAttachmentTexture

@synthesize compositedImage = _compositedImage;

- (instancetype __nullable)initWithDictionary:(NSDictionary *__nonnull)dict {
    id idValue = dict[@"srcId"];
    NSString *attachmentID = nil;
    if ([idValue isKindOfClass:NSString.class]) {
        attachmentID = [idValue copy];
    } else {
        attachmentID = [NSString stringWithFormat:@"%@", idValue];
    }
    if (attachmentID.length == 0) {
        return nil;
    }
    NSString *type = [dict valueForKey:@"srcType"];
    if (![type isKindOfClass:NSString.class]) {
        return nil;
    }
    if (![type isEqualToString:@"img"] && ![type isEqualToString:@"txt"]) {
        return nil;
    }
    NSString *tag = [dict valueForKey:@"srcTag"];
    if (![tag isKindOfClass:NSString.class]) {
        tag = @"";
    }
    CGFloat width = MEKHVACMaskParseFloat(dict[@"w"]);
    CGFloat height = MEKHVACMaskParseFloat(dict[@"h"]);
    if (width <= 0 || height <= 0) {
        return nil;
    }
    self = [super init];
    if (self) {
        NSString *ct = [dict valueForKey:@"fitType"];
        if ([ct isKindOfClass:NSString.class] && [ct isEqualToString:@"centerFull"]) {
            _contentMode = MEKHVACMaskAttachmentContentModeAspectFill;
        } else {
            _contentMode = MEKHVACMaskAttachmentContentModeAspectFit;
        }
        if ([type isEqualToString:@"img"]) {
            _contentType = MEKHVACMaskAttachmentContentTypeImage;
        } else {
            _contentType = MEKHVACMaskAttachmentContentTypeText;
        }
        _textureID = [attachmentID copy];
        _contentTag = [tag copy];
        _width = width;
        _height = height;
        _lock = [[NSLock alloc] init];
    }
    return self;
    
}

- (void)setCompositedImage:(CIImage *)compositedImage {
    [_lock lock];
    _compositedImage = compositedImage;
    [_lock unlock];
}

- (CIImage *)compositedImage {
    CIImage *result;
    [_lock lock];
    result = _compositedImage;
    [_lock unlock];
    return result;
}

@end
