//
//  LMCommandSendManager.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/28.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.pbobjc.h"
#import "Message.h"

typedef void (^SocketCallback)(id data,NSError *error);

@interface SendCommandModel : NSObject

@property(nonatomic, strong) CommandMessage *sendMsg;
@property(nonatomic, strong) GPBMessage *requestData;
@property(nonatomic, assign) long long sendTime;
@property(nonatomic, copy) SocketCallback callBack;

@end

@interface LMCommandSendManager : NSObject

+ (instancetype)sharedManager;

- (void)addSendingCommandMessage:(CommandMessage *)message originContent:(GPBMessage *)originContent callBack:(SocketCallback)callBack;

- (void)receiveCommandMessage:(Message *)commandMsg;

- (void)sendCommandFailedWithCommandId:(NSString *)commandId;

@end
