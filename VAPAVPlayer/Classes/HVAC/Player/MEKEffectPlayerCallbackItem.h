//
//  MEKEffectPlayerCallbackItem.h
//  MEKEffectPlayer
//
//  Created by 孙江挺 on 2022/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEKEffectPlayerCallbackItem : NSObject

@property (nonatomic) BOOL hasCallbackStart;
@property (nonatomic) BOOL hasCallbackReady;
@property (nonatomic) BOOL hasCallbackFinish;
@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) NSInteger playCount;
@property (nonatomic) NSInteger failedCount;

@property (nonatomic) NSTimeInterval duration;

@property (nonatomic, strong, readonly, nonnull) NSURL *url;

- (instancetype)initWithURL:(NSURL *__nonnull)url NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *userInfo;


@end

NS_ASSUME_NONNULL_END
