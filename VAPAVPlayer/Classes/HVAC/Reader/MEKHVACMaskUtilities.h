//
//  MEKHVACMaskUtilities.h
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/30.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEKHVACMaskUtilities : NSObject

@end


static inline CGFloat MEKHVACMaskParseFloat(id value) {
    if (![value respondsToSelector:@selector(floatValue)]) {
        return 0;
    }
    return [value floatValue];
}

static inline NSInteger MEKHVACMaskParseInteger(id value) {
    if (![value respondsToSelector:@selector(integerValue)]) {
        return 0;
    }
    return [value integerValue];
}

static inline CGRect MEKHVACMaskParseFrame(id frameValue) {
    if (![frameValue isKindOfClass:NSArray.class]) {
        return CGRectZero;
    }
    NSArray *frameNumbers = (NSArray *)frameValue;
    if (frameNumbers.count < 4) {
        return CGRectZero;
    }
    CGFloat values[4];
    NSInteger valueCount = 0;
    for (id value in frameNumbers) {
        if (![value respondsToSelector:@selector(floatValue)]) {
            continue;
        }
        CGFloat v = [(NSNumber *)value floatValue];
        if (valueCount >= 4) {
            break;
        }
        values[valueCount ++] = v;
    }
    if (valueCount < 4) {
        return CGRectZero;
    }
    return CGRectMake(values[0], values[1], values[2], values[3]);
}


NS_ASSUME_NONNULL_END
