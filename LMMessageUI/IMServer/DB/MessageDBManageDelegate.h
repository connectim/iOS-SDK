//
//  MessageDBManageDelegate.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/9.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMessage.h"

@protocol MessageDBManageDelegate <NSObject>

/// 保存消息
- (void)saveMessage:(LMMessage *)message;
/// 保存消息
- (void)batchSaveMessage:(NSArray <LMMessage *>*)messagees;
/// 更新消息状态
- (void)updateMessageStatus:(LMMessageStatus)status withMessageOwer:(NSString *)msgOwer messageId:(NSString *)messageId;
/// 查询消息
- (NSArray <LMMessage *>*)fetchMessageFromTime:(NSDate *)lastMessageTime limit:(int)limit;

@end
