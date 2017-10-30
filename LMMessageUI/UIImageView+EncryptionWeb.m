//
//  UIImageView+EncryptionWeb.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "UIImageView+EncryptionWeb.h"
#import <AFNetworking/AFNetworking.h>
#import <YYKit/YYKit.h>
#import "NSString+Hex.h"
#import "NSData+Hex.h"
#import "LMMessageTool.h"

static AFHTTPSessionManager *manager;

@implementation UIImageView (EncryptionWeb)

- (void)setImageWithURL:(NSURL *)URL placeholder:(UIImage *)placeholder withECDHKey:(NSData *)ECDHKey completion:(YYWebImageCompletionBlock)completion {
    if (!URL) {
        self.image = placeholder;
        return;
    }
    ///查到内存图片
    UIImage *cacheImage = [[YYImageCache sharedCache] getImageForKey:URL.absoluteString.sha1String withType:YYImageCacheTypeMemory];
    if (cacheImage) {
        self.image = cacheImage;
        if (completion) {
            completion(cacheImage,URL,YYWebImageFromMemoryCache,YYWebImageStageFinished,nil);
        }
        return;
    }
    
    ///查找本地图片
    cacheImage = [[YYImageCache sharedCache] getImageForKey:URL.absoluteString.sha1String withType:YYImageCacheTypeDisk];
    if (cacheImage) {
        self.image = cacheImage;
        if (completion) {
            completion(cacheImage,URL,YYWebImageFromDiskCache,YYWebImageStageFinished,nil);
        }
        return;
    }
    
    self.image = placeholder;
    
    ///下载图片并保存在内存和本地缓存中
    if (!manager) {
        manager = [AFHTTPSessionManager manager];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *filePath = [cachePath stringByAppendingPathComponent:URL.absoluteString.sha1String];
        return [[NSURL alloc] initFileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (!error) {
            NSData *data = [NSData dataWithContentsOfURL:filePath];
            GcmData *gcm = [GcmData parseFromData:data error:nil];
            /// 解码
            NSData *imageData = [LMMessageTool decodeGcmDataWithEmptySaltEcdhKey:ECDHKey GcmData:gcm havePlainData:YES];
            UIImage *image = [UIImage imageWithData:imageData];
            if (completion) {
                completion(image,response.URL,YYWebImageFromRemote,YYWebImageStageFinished,nil);
            }
            /// 设置缓存
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });
            [[YYImageCache sharedCache] setImage:image imageData:imageData forKey:URL.absoluteString.sha1String withType:YYImageCacheTypeAll];
            /// 清除临时下载数据
            [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
        } else {
            if (completion) {
                completion(nil,response.URL,YYWebImageFromRemote,YYWebImageStageFinished,error);
            }
        }
    }];
    [downloadTask resume];
}

- (void)setImageWithURL:(NSURL *)URL ECDHKey:(NSData *)ECDHKey {
    [self setImageWithURL:URL placeholder:[UIImage imageNamed:@"image_placeholder"] withECDHKey:ECDHKey completion:nil];
}

@end
