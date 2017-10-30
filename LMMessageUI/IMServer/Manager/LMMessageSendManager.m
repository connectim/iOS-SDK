//
//  LMMessageSendManager.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageSendManager.h"
#import "LMConnectIMChater.h"

typedef NS_ENUM(NSInteger, MessageRejectErrorType) {
    MessageRejectErrorTypeUnknow = 0,
    MessageRejectErrorTypeNotExisted = 1,
    MessageRejectErrorTypeNotFriend = 2,
    MessageRejectErrorTypeBlackList = 3,
    MessageRejectErrorTypeNotInGroup = 4,
    MessageRejectErrorTypeChatinfoEmpty = 5,
    MessageRejectErrorTypeGetChatinfoError = 6,
    MessageRejectErrorTypeChatinfoNotMatch = 7,
    MessageRejectErrorTypeChatinfoExpire = 8,
    MessageRejectErrorTypeMyChatCookieNotMatch = 9,
};

@implementation SendMessageModel

@end


@interface LMMessageSendManager ()

@property(nonatomic, strong) dispatch_queue_t messageSendStatusQueue;
@property(nonatomic, strong) NSMutableDictionary *sendingMessages;


//check message outtime
@property(nonatomic, strong) dispatch_source_t reflashSendStatusSource;
@property(nonatomic, assign) BOOL reflashSendStatusSourceActive;

@end

@implementation LMMessageSendManager


+ (instancetype)sharedManager {
    static LMMessageSendManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LMMessageSendManager alloc] init];
    });
    
    return _instance;
}


- (instancetype)init {
    if (self = [super init]) {
        _sendingMessages = [NSMutableDictionary dictionary];

        _messageSendStatusQueue = dispatch_queue_create("_imserver_message_sendstatus_queue", DISPATCH_QUEUE_SERIAL);

        //relash source
        __weak __typeof(&*self) weakSelf = self;
        _reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _messageSendStatusQueue);
        dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
            if (weakSelf.sendingMessages.allKeys.count <= 0) {
                dispatch_suspend(_reflashSendStatusSource);
                weakSelf.reflashSendStatusSourceActive = NO;
            }
            NSArray *sendMessageModels = weakSelf.sendingMessages.allValues.copy;
            for (SendMessageModel *sendMessageModel in sendMessageModels) {
                int long long currentTime = [[NSDate date] timeIntervalSince1970];
                int long long sendDuration = currentTime - sendMessageModel.sendTime;
                if (sendDuration >= SOCKET_TIME_OUT) {
                    //update message send status
                    sendMessageModel.sendMsg.sendStatus = LMMessageStatusFailed;
                    //update status
                    if (sendMessageModel.callBack) {
                        sendMessageModel.callBack(sendMessageModel.sendMsg, [NSError errorWithDomain:@"over_time" code:OVER_TIME_CODE userInfo:nil]);
                    }
                    [weakSelf.sendingMessages removeObjectForKey:sendMessageModel.sendMsg.msgId];
                }
            }
        });
        dispatch_resume(_reflashSendStatusSource);
        _reflashSendStatusSourceActive = YES;
    }
    return self;
}


- (void)addSendingMessage:(ChatMessage *)message originContent:(GPBMessage *)originContent callBack:(SendMessageCallBlock)callBack {
    SendMessageModel *sendMessageModel = [SendMessageModel new];
    sendMessageModel.sendMsg = message;
    sendMessageModel.originContent = originContent;
    sendMessageModel.sendTime = [[NSDate date] timeIntervalSince1970];
    sendMessageModel.callBack = callBack;
    
    //save to send queue
    [self.sendingMessages setValue:sendMessageModel forKey:message.msgId];
    
    //open reflash
    if (!self.reflashSendStatusSourceActive) {
        dispatch_resume(self.reflashSendStatusSource);
        self.reflashSendStatusSourceActive = YES;
    }
}


- (void)messageSendSuccessMessageId:(NSString *)messageId {
    if (messageId.length == 0) {
        return;
    }
    dispatch_async(self.messageSendStatusQueue, ^{
        SendMessageModel *sendModel = [self.sendingMessages valueForKey:messageId];
        //update status
        sendModel.sendMsg.sendStatus = LMMessageStatusSuccess;
        if (sendModel.callBack) {
            sendModel.callBack(sendModel.sendMsg, nil);
        }
        /// 发送消息发送成功的通知
//        SendNotify(ConnnectSendMsgSuccessNotification, messageId);
        [self.sendingMessages removeObjectForKey:messageId];
    });
}

- (void)messageSendFailedMessageId:(NSString *)messageId {
    
    dispatch_async(self.messageSendStatusQueue, ^{
        SendMessageModel *sendModel = [self.sendingMessages valueForKey:messageId];
        sendModel.sendMsg.sendStatus = LMMessageStatusFailed;
        if (sendModel.callBack) {
            NSError *error = [NSError errorWithDomain:@"imserver" code:-1 userInfo:nil];
            sendModel.callBack(sendModel.sendMsg, error);
        }
        
        //remove
        [self.sendingMessages removeObjectForKey:messageId];
    });
}

- (void)messageRejectedMessage:(RejectMessage *)rejectMsg {
    dispatch_async(self.messageSendStatusQueue, ^{
        SendMessageModel *sendModel = [self.sendingMessages valueForKey:rejectMsg.msgId];
        
        MessageRejectErrorType rejectErrorType = (NSInteger) rejectMsg.status;
        switch (rejectErrorType) {
            case MessageRejectErrorTypeGetChatinfoError: /// 直接发送失败
            case MessageRejectErrorTypeNotExisted:{
                NSString *identifier = rejectMsg.uid;
                if (identifier.length != 0) {
                    //create tip message
                    /// 发送失败原因
//                    SendNotify(ConnnectSendMsgFailedWithErrorNotification, chatMsgInfo);
                    if (sendModel.callBack) {
                        sendModel.callBack(sendModel.sendMsg, nil);
                    }
                }
            }
                break;
            case MessageRejectErrorTypeMyChatCookieNotMatch: {
                [[LMConnectIMChater sharedManager] uploadCookieWithComplete:^(id data, NSError *error) {
                    if (!error) {
                        
                        /// 发送消息
                    }
                }];
            }
                break;
            case MessageRejectErrorTypeChatinfoEmpty:
            case MessageRejectErrorTypeChatinfoExpire: {
                NSString *identifier = rejectMsg.uid;
                [LMConnectIMChater sharedManager].chatSessionManager;
//                [[SessionManager sharedManager] removeChatCookieWithChatSession:identifier];
//                if (rejectErrorType == MessageRejectErrorTypeChatinfoExpire) {
//                    [[SessionManager sharedManager] chatCookie:YES chatSession:identifier];
//                }
//                [[IMService instance] asyncSendMessage:sendModel.sendMsg originContent:sendModel.originContent sendMessageCompletion:sendModel.callBack];
            }
                break;
            case MessageRejectErrorTypeChatinfoNotMatch: {
                ChatCookie *chatCookie = [ChatCookie parseFromData:rejectMsg.data_p error:nil];
//                NSString *identifier = rejectMsg.uid;
//                if ([ConnectTool vertifyWithData:chatCookie.data_p.data sign:chatCookie.sign publickey:identifier]) {
//                    ChatCookieData *chatInfo = chatCookie.data_p;
//                    [[SessionManager sharedManager] setChatCookie:chatInfo chatSession:identifier];
//                    [[IMService instance] asyncSendMessage:sendModel.sendMsg originContent:sendModel.originContent sendMessageCompletion:sendModel.callBack];
//                } else {
//                    if (sendModel.callBack) {
//                        sendModel.sendMsg.sendStatus = GJGCChatFriendSendMessageStatusFaild;
//                        NSError *error = [NSError errorWithDomain:@"imserver" code:-1 userInfo:nil];
//                        sendModel.callBack(sendModel.sendMsg, error);
//                        
//                        //update message send status
//                        [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFaild withMessageId:rejectMsg.msgId messageOwer:identifier];
//                    }
//                }
            }
                break;
            case MessageRejectErrorTypeNotInGroup: {
                NSString *identifier = rejectMsg.uid;
                [[[LMConnectIMChater sharedManager] messageDBManager] updateMessageStatus:LMMessageStatusNotInGroup withMessageOwer:identifier messageId:rejectMsg.msgId];
                
//                if (!GJCFStringIsNull(identifier)) {
//                    //updata message sendstatus
//                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNotInGroup withMessageId:rejectMsg.msgId messageOwer:identifier];
//                    sendModel.sendMsg.sendStatus = GJGCChatFriendSendMessageStatusFailByNotInGroup;
//                    //create tip message
//                    ///LMLocalizedString(@"Message send fail not in group", nil)
//                    ChatMessageInfo *chatMsgInfo = [[MessageDBManager sharedManager] createTipMessageWithMessageOwer:identifier content:nil notifyType:NotifyMessageTypeNotInGroup];
//                    /// 发送失败原因
//                    SendNotify(ConnnectSendMsgFailedWithErrorNotification, chatMsgInfo);
//                    if (sendModel.callBack) {
//                        sendModel.callBack(sendModel.sendMsg, nil);
//                    }
//                    //update message send status
//                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNotInGroup withMessageId:rejectMsg.msgId messageOwer:identifier];
//                    
//                }
            }
                break;
            case MessageRejectErrorTypeNotFriend: {
                NSString *identifier = rejectMsg.uid;
//                if (!GJCFStringIsNull(identifier)) {
//                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNoRelationShip withMessageId:rejectMsg.msgId messageOwer:identifier];
//                    sendModel.sendMsg.sendStatus = GJGCChatFriendSendMessageStatusFailByNoRelationShip;
//                    //create tip message  ,content : 对方的uid
//                    ChatMessageInfo *chatMsgInfo = [[MessageDBManager sharedManager] createTipMessageWithMessageOwer:identifier content:identifier notifyType:NotifyMessageTypeNoFriend];
//                    /// 发送失败原因
//                    SendNotify(ConnnectSendMsgFailedWithErrorNotification, chatMsgInfo);
//                    if (sendModel.callBack) {
//                        sendModel.callBack(sendModel.sendMsg, nil);
//                    }
//                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNoRelationShip withMessageId:rejectMsg.msgId messageOwer:identifier];
//                }
            }
                break;
                
            case MessageRejectErrorTypeBlackList: {
                
                NSString *identifier = rejectMsg.uid;
//                if (!GJCFStringIsNull(identifier)) {
//                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccessUnArrive withMessageId:rejectMsg.msgId messageOwer:identifier];
//                    
//                    sendModel.sendMsg.sendStatus = GJGCChatFriendSendMessageStatusSuccessUnArrive;
//                    //create tip message LMLocalizedString(@"Link Message has been sent the other rejected", nil)
//                    ChatMessageInfo *chatMsgInfo = [[MessageDBManager sharedManager] createTipMessageWithMessageOwer:identifier content:nil notifyType:NotifyMessageTypeSeedButRejected];
//                    /// 发送失败原因
//                    SendNotify(ConnnectSendMsgFailedWithErrorNotification, chatMsgInfo);
//                    if (sendModel.callBack) {
//                        sendModel.callBack(sendModel.sendMsg, nil);
//                    }
//                    
//                    //update message send status
//                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccessUnArrive withMessageId:rejectMsg.msgId messageOwer:identifier];
//                }
            }
                break;
            default:
                break;
        }
        /// 发送消息发送失败的通知
//        SendNotify(ConnnectSendMsgFailedNotification, rejectMsg.msgId);
        //remove send queue message
        [self.sendingMessages removeObjectForKey:rejectMsg.msgId];

    });
}


@end
