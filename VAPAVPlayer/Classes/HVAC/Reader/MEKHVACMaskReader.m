//
//  MEKHVACMaskReader.m
//  MEKBasic
//
//  Created by 孙江挺 on 2023/8/29.
//

#import "MEKHVACMaskReader.h"

#define MEK_FOURCC_TYPE(a, b, c, d) ((d) | ((c) << 8) | ((b) << 16) | ((unsigned)(a) << 24))

#define MEK_TYPE_TO_FOURCC(type) [NSString stringWithCharacters:(unichar []){(unichar)((type >> 24) & 0xFF), (unichar)((type >> 16) & 0xFF), (unichar)((type >> 8) & 0xFF), (unichar)(type & 0xFF)} length:4]

typedef struct MEKMP4BoxHeader {
    int32_t length;
    int32_t type;
} MEKMP4BoxHeader;

@implementation MEKHVACMaskReader

+ (MEKHVACMaskContent *__nullable)maskContentWithFileURL:(NSURL *)fileURL {
    if (!fileURL || !fileURL.isFileURL) {
        return nil;
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:fileURL.path];
    if (!fileHandle) {
        return nil;
    }
    long long fileLength = [fileHandle seekToEndOfFile];
    if (fileLength <= 8) {
        return nil;
    }
    [fileHandle seekToFileOffset:0];
    
    BOOL hasSuperBox = NO;
    long long offset = 0;
    while (offset < fileLength) {
        [fileHandle seekToFileOffset:offset];
        NSData *data = [fileHandle readDataOfLength:8];
        MEKMP4BoxHeader header = *((MEKMP4BoxHeader *)data.bytes);
        int32_t type =  CFSwapInt32BigToHost(header.type);
        /// 如果第一个 box 不是 ftyp，则认为不是 mp4 格式，直接返回为空
        if (!hasSuperBox && (type != MEK_FOURCC_TYPE('f', 't', 'y', 'p'))) {
            return nil;
        }
        int32_t length = CFSwapInt32BigToHost(header.length);
        
        hasSuperBox = YES;
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


/// 以下内容为测试用具，正式可以删除。 作用是把 A 视频的 vapc 内容拷贝到 B 视频上。 由于 ffmpeg 转换过程中可能会丢失 vapc 信息，所以提供复制方法
/*
NSData *MEKReadMaskContentWithFileURL(NSURL *fileURL) {
    if (!fileURL || !fileURL.isFileURL) {
        return nil;
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:fileURL.path];
    if (!fileHandle) {
        return nil;
    }
    long long fileLength = [fileHandle seekToEndOfFile];
    if (fileLength <= 8) {
        return nil;
    }
    [fileHandle seekToFileOffset:0];
    
    BOOL hasSuperBox = NO;
    long long offset = 0;
    while (offset < fileLength) {
        [fileHandle seekToFileOffset:offset];
        NSData *data = [fileHandle readDataOfLength:8];
        MEKMP4BoxHeader header = *((MEKMP4BoxHeader *)data.bytes);
        int32_t type =  CFSwapInt32BigToHost(header.type);
        NSLog(@"%@", MEK_TYPE_TO_FOURCC(type));
        /// 如果第一个 box 不是 ftyp，则认为不是 mp4 格式，直接返回为空
        if (!hasSuperBox && (type != MEK_FOURCC_TYPE('f', 't', 'y', 'p'))) {
            return nil;
        }
        int32_t length = CFSwapInt32BigToHost(header.length);
        
        hasSuperBox = YES;
        if (type == MEK_FOURCC_TYPE('v', 'a', 'p', 'c')) {
            if (offset + length > fileLength) {
                return nil;
            }
            NSData *jsonData = [fileHandle readDataOfLength:length - 8];
            NSMutableData *allData = [NSMutableData data];
            [allData appendData:data];
            [allData appendData:jsonData];
            return allData;
        }
        offset += length;
    }
    return nil;
}

NSData *MEKWriteMaskContentWithData(NSData *boxData, NSURL *fileURL) {
    if (!fileURL || !fileURL.isFileURL) {
        return nil;
    }
    if (!boxData) {
        return nil;
    }
    NSMutableData *allData = [NSMutableData dataWithContentsOfURL:fileURL];
    if (!allData) {
        return nil;
    }
    NSInteger fileLength = allData.length;
    BOOL hasInserted = NO;
    long long offset = 0;
    while (offset < fileLength) {
        NSData *data = [allData subdataWithRange:NSMakeRange(offset, 8)];
        MEKMP4BoxHeader header = *((MEKMP4BoxHeader *)data.bytes);
        int32_t type =  CFSwapInt32BigToHost(header.type);
        int32_t length = CFSwapInt32BigToHost(header.length);
        NSString *stype = MEK_TYPE_TO_FOURCC(type);
        if ([stype isEqualToString:@"moov"]) {
            NSInteger index = offset + length;
            [allData replaceBytesInRange:NSMakeRange(index, 0) withBytes:boxData.bytes length:boxData.length];
            hasInserted = YES;
            break;
        }
        offset += length;
    }
    return allData;
}

void MEKCopyMaskContentWithFiles(NSString *sourceFile, NSString *targetFile, NSString *outputFile) {
    NSURL *sourceURL = [NSURL fileURLWithPath:sourceFile];
    NSURL *targetURL = [NSURL fileURLWithPath:targetFile];
    if (MEKReadMaskContentWithFileURL(targetURL)) {
        return;
    }
    NSData *boxData = MEKReadMaskContentWithFileURL(sourceURL);
    if (!boxData) {
        return;
    }
    NSData *newData = MEKWriteMaskContentWithData(boxData, targetURL);
    [newData writeToFile:outputFile atomically:YES];
}

*/
