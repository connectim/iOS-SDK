//
//  LMDownLoadManager.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/10.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMDownLoadManager : NSObject

+ (instancetype)sharedManager;

- (void)downloadVideoWithUrl:(NSString *)videoUrl videoName:(NSString *)videoName ECDHKey:(NSData *)ECDHKey progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock complete:(void (^)(NSURL *videoUrl,NSError *error))complete;

@end
