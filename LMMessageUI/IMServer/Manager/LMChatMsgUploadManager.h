//
//  LMChatMsgUploadManager.h
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Message.pbobjc.h"

@interface LMChatMsgUploadManager : NSObject

+ (LMChatMsgUploadManager *)shareManager;

- (void)uploadMainData:(NSData *)mainData minorData:(NSData *)minorData encryptECDH:(NSData *)ecdhkey to:(NSString *)to msgId:(NSString *)msgId chatType:(int)chatType originMsg:(GPBMessage *)originMsg progress:(void (^)(NSString *to,NSString *msgId,CGFloat progress))progress  complete:(void(^)(GPBMessage *originMsg,NSString *to,NSString *msgId,NSError *error))completion;

@end
