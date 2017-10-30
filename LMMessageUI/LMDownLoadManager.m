//
//  LMDownLoadManager.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/10.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMDownLoadManager.h"
#import <AFNetworking/AFNetworking.h>
#import "Message.pbobjc.h"
#import "LMMessageTool.h"

static AFHTTPSessionManager *downloadManager;

@implementation LMDownLoadManager

+ (instancetype)sharedManager {
    static LMDownLoadManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LMDownLoadManager alloc] init];
    });
    return _instance;
}

- (void)downloadVideoWithUrl:(NSString *)videoUrl videoName:(NSString *)videoName ECDHKey:(NSData *)ECDHKey progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock complete:(void (^)(NSURL *videoUrl,NSError *error))complete {
    NSString *documentPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"videomsg"];
    if (!downloadManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        downloadManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        BOOL isdir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath isDirectory:&isdir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    NSURL *URL = [NSURL URLWithString:videoUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSessionDownloadTask *downloadTask = [downloadManager downloadTaskWithRequest:request progress:downloadProgressBlock destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES) lastObject];
        return [[NSURL alloc] initFileURLWithPath:[cachePath stringByAppendingPathComponent:videoName]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            NSData *data =  [NSData dataWithContentsOfURL:filePath];
            GcmData *gcmData = [GcmData parseFromData:data error:nil];
            NSData *mp4Data = [LMMessageTool decodeGcmData:gcmData ECDHKey:ECDHKey needEmptySalt:YES havePlainData:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                /// 保存视频文件
                NSString *mp4Name = [NSString stringWithFormat:@"%@.mp4",videoName];
                NSString *mp4Path = [documentPath stringByAppendingPathComponent:mp4Name];
                [mp4Data writeToFile:mp4Path atomically:YES];
                /// 移除临时文件
                [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) {
                        complete([NSURL fileURLWithPath:mp4Path],nil);
                    }
                });
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) {
                    complete(nil,error);
                }
            });
        }
    }];
    
    [downloadTask resume];
}

@end
