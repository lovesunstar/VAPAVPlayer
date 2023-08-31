//
//  MEKHVACMaskAttachmentTexture.h
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/30.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CIImage;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MEKHVACMaskAttachmentContentMode) {
    MEKHVACMaskAttachmentContentModeAspectFit,
    MEKHVACMaskAttachmentContentModeAspectFill
};

typedef NS_ENUM(NSUInteger, MEKHVACMaskAttachmentContentType) {
    MEKHVACMaskAttachmentContentTypeText,
    MEKHVACMaskAttachmentContentTypeImage
};

@interface MEKHVACMaskAttachmentTexture : NSObject

@property (nonatomic, copy, readonly, nonnull) NSString *textureID;
@property (nonatomic, readonly) MEKHVACMaskAttachmentContentMode contentMode;
@property (nonatomic, readonly) MEKHVACMaskAttachmentContentType contentType;
@property (nonatomic, readonly, nullable, copy) NSString *contentTag;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;

- (instancetype __nullable)initWithDictionary:(NSDictionary *__nonnull)dict;

@property (nonatomic, strong) CIImage *compositedImage;

@end

NS_ASSUME_NONNULL_END
