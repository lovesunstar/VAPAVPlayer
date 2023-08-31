//
//  MEKEffectPlayerCallbackItem.m
//  MEKEffectPlayer
//
//  Created by 孙江挺 on 2022/3/18.
//

#import "MEKEffectPlayerCallbackItem.h"

@implementation MEKEffectPlayerCallbackItem

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

@end
