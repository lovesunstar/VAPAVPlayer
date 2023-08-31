//
//  MEKHVACMaskReader.h
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/29.
//

#import <Foundation/Foundation.h>
#import "MEKHVACMaskContent.h"

NS_ASSUME_NONNULL_BEGIN
/// 解析 mp4 中的 vapc 内容. vapc 内容为 json 格式，大概格式如下：
/// vapc
/// {
///    info: 包含视频信息，rgb 区域，alpha 区域，尺寸大小，帧率等。
///    frame: 每一帧上面的遮罩层信息
/// }
/// frame，遮罩
/// {
///    i: 代表第几帧的遮罩
///    obj: 内容数组
/// }
///
/// obj，遮罩内容
/// {
///    srcId: 对应 src 信息，可能是文本图片之类的
///    z: z index, 图层顺序
///    frame: 遮罩内容相对于视频的坐标
///    mFrame: 遮罩内容 mask 区域。（相对于整个原始视频）
/// }
///
@interface MEKHVACMaskReader : NSObject

+ (MEKHVACMaskContent *__nullable)maskContentWithFileURL:(NSURL *__nonnull)fileURL NS_SWIFT_NAME(maskContent(fileURL:));

@end

NS_ASSUME_NONNULL_END
