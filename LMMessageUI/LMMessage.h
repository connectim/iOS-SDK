//
//  LMMessage.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMMessageConstant.h"
#import "Message.pbobjc.h"

@interface LMMessage : NSObject

@property (nonatomic ,copy) NSString *msgOwer;
@property (nonatomic ,copy) NSString *msgId;
@property (nonatomic ,copy) NSString *senderId;
@property (nonatomic ,copy) NSString *from;
@property (nonatomic ,strong) NSDate *createTime;
@property (nonatomic ,assign) LMMessageStatus status;
@property (nonatomic ,assign) LMMessageType msgType;
@property (nonatomic ,assign) LMChatType chatType;
@property (nonatomic ,assign) BOOL sendFromSelf;
@property (nonatomic ,strong) id msgContent;

@end
