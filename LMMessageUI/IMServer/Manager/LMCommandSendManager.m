//
//  LMCommandSendManager.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/28.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMCommandSendManager.h"
#import "LMConnectIMChater.h"
#import "LMEncryptKit.h"
#import "NSData+Hash.h"
#import "LMIMMessageHandler.h"

@interface LMCommandSendManager ()

@property(nonatomic, strong) dispatch_queue_t commandMessageSendStatusQueue;
@property(nonatomic, strong) NSMutableDictionary *sendingCommandMessages;


//check message outtime
@property(nonatomic, strong) dispatch_source_t reflashSendStatusSource;
@property(nonatomic, assign) BOOL reflashSendStatusSourceActive;

@end

@implementation LMCommandSendManager

+ (instancetype)sharedManager {
    static LMCommandSendManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LMCommandSendManager alloc] init];
    });
    
    return _instance;
}


- (instancetype)init {
    if (self = [super init]) {
        _sendingCommandMessages = [NSMutableDictionary dictionary];
        _commandMessageSendStatusQueue = dispatch_queue_create("_imserver_message_sendstatus_queue", DISPATCH_QUEUE_SERIAL);
        //relash source
        __weak __typeof(&*self) weakSelf = self;
        _reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _commandMessageSendStatusQueue);
        dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
            if (weakSelf.sendingCommandMessages.allKeys.count <= 0) {
                dispatch_suspend(_reflashSendStatusSource);
                weakSelf.reflashSendStatusSourceActive = NO;
            }
            NSArray *sendMessageModels = weakSelf.sendingCommandMessages.allValues.copy;
            for (SendCommandModel *sendMessageModel in sendMessageModels) {
                int long long currentTime = [[NSDate date] timeIntervalSince1970];
                int long long sendDuration = currentTime - sendMessageModel.sendTime;
                if (sendDuration >= SOCKET_TIME_OUT) {
                    //update status
                    if (sendMessageModel.callBack) {
                        sendMessageModel.callBack(sendMessageModel.sendMsg, [NSError errorWithDomain:@"over_time" code:OVER_TIME_CODE userInfo:nil]);
                    }
                    [weakSelf.sendingCommandMessages removeObjectForKey:sendMessageModel.sendMsg.commandId];
                }
            }
        });
        dispatch_resume(_reflashSendStatusSource);
        _reflashSendStatusSourceActive = YES;
    }
    return self;
}

- (void)addSendingCommandMessage:(CommandMessage *)message originContent:(GPBMessage *)originContent callBack:(SocketCallback)callBack {
    SendCommandModel *sendMessageModel = [SendCommandModel new];
    sendMessageModel.sendMsg = message;
    sendMessageModel.requestData = originContent;
    sendMessageModel.sendTime = [[NSDate date] timeIntervalSince1970];
    sendMessageModel.callBack = callBack;
    //save to send queue
    [self.sendingCommandMessages setValue:sendMessageModel forKey:message.commandId];
    //open reflash
    if (!self.reflashSendStatusSourceActive) {
        dispatch_resume(self.reflashSendStatusSource);
        self.reflashSendStatusSourceActive = YES;
    }
}

- (void)sendCommandFailedWithCommandId:(NSString *)commandId {
    
    dispatch_async(self.commandMessageSendStatusQueue, ^{
        SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:commandId];
        if (sendComModel.callBack) {
            NSError *error = [NSError errorWithDomain:@"imserver_error" code:-1 userInfo:nil];
            sendComModel.callBack(error, nil);
        }
        //remove
        [self.sendingCommandMessages removeObjectForKey:commandId];
    });
}


- (void)receiveCommandMessage:(Message *)commandMsg {
    dispatch_async(self.commandMessageSendStatusQueue, ^{
        Command *command = nil;
        if (commandMsg.extension != BM_GETOFFLINE_EXT) {
            NSError *error = nil;
            command = [Command parseFromData:commandMsg.body error:&error];
            if (error) {
                return;
            }
        }
        switch (commandMsg.extension) {
            case BM_GETOFFLINE_EXT: {
                [self offlineMessage:commandMsg.body];
            }
                break;
            case BM_UNBINDDEVICETOKEN_EXT: {
                [self deviceTokenUnbind:command];
            }
                break;
            case BM_BINDDEVICETOKEN_EXT: {
                [self deviceTokenBind:command];
            }
                break;
            case BM_NEWFRIEND_EXT: {
                [self friendRequest:command];
            }
                break;
            case BM_FRIENDLIST_EXT: {
                [self friendList:command];
            }
                break;
            case BM_ACCEPT_NEWFRIEND_EXT: {
                [self acceptRequest:command];
            }
                break;
            case BM_DELETE_FRIEND_EXT: {
                [self deleteUser:command];
            }
                break;
            case BM_SET_FRIENDINFO_EXT: {
                [self setUserInfo:command];
            }
                break;
            case BM_GROUPINFO_CHANGE_EXT: {
                [self groupInfoChange:command];
            }
                break;
            case BM_SYNCBADGENUMBER_EXT: {
                [self syncBadgeNumber:command];
            }
                break;
            case BM_CREATE_SESSION: {
                [self createSession:command];
            }
                break;
            case BM_SETMUTE_SESSION: {
                [self sessionMute:command];
            }
                break;
            case BM_DELETE_SESSION: {
                [self deleteSession:command];
            }
                break;
            case BM_OUTER_TRANSFER_EXT: {
                [self urlTransfer:command];
            }
                break;
            case BM_OUTER_REDPACKET_EXT: {
                [self urlRedpacket:command];
            }
                break;
            case BM_RECOMMADN_NOTINTEREST_EXT: {
                [self recommandNointeret:command];
            }
                break;
            case BM_UPLOAD_CHAT_COOKIE_EXT: {
                [self uploadChatCookieAck:command];
            }
                break;
            case BM_FRIEND_CHAT_COOKIE_EXT:
                [self userChatCookie:command];
                break;
            case BM_FROCEUODATA_CHAT_COOKIE_EXT: {
                [self loginOnNewPhoneUploadChatCookie:command];
            }
                break;
            default:
                break;
        }
        if (command) {
            //remove command
            [self.sendingCommandMessages removeObjectForKey:command.msgId];
            [[LMConnectIMChater sharedManager] sendOnlineAck:command.msgId type:commandMsg.typechar];
        }
    });
}


- (void)offlineMessage:(NSData *)offlineMsgData {
    NSData *offlineData = nil;
    OfflineMsgs *offlinemsg = [OfflineMsgs parseFromData:offlineData error:nil];
    NSMutableArray *ackMessageIds = [NSMutableArray array];
    for (OfflineMsg *messageDetail in offlinemsg.offlineMsgsArray) {
        [ackMessageIds addObject:messageDetail.msgId];
        int type = messageDetail.body.type;
        int extension = messageDetail.body.ext;
        if (messageDetail.body.data_p.length == 0) {
            continue;
        }
        switch (type) {
            case BM_IM_TYPE: {
                Message *imMessage = [Message new];
                imMessage.typechar = BM_IM_TYPE;
                imMessage.extension = extension;
                switch (extension) {
                    case BM_SERVER_NOTE_EXT:
                    {
                        NoticeMessage *notice = [NoticeMessage parseFromData:messageDetail.body.data_p error:nil];
                        imMessage.body = notice;
                    }
                        break;
                    case BM_IM_ROBOT_EXT:
                    {
                        MSMessage *sysMsg = [MSMessage parseFromData:messageDetail.body.data_p error:nil];
                        imMessage.body = sysMsg;
                    }
                        break;
                    case BM_IM_MESSAGE_ACK_EXT:
                    case BM_IM_EXT:
                    case BM_IM_SEND_GROUPINFO_EXT:
                    case BM_IM_GROUPMESSAGE_EXT:
                    {
                        MessagePost *post = [MessagePost parseFromData:messageDetail.body.data_p error:nil];
                        imMessage.body = post;
                    }
                        break;
                    default:
                        break;
                }
                [LMIMMessageHandler handldOfflineMessage:imMessage];
            }
                break;
            case BM_COMMAND_TYPE: {
                Message *commandMessage = [Message new];
                commandMessage.typechar = BM_COMMAND_TYPE;
                commandMessage.extension = extension;
                commandMessage.body = messageDetail.body.data_p;
                [self receiveCommandMessage:commandMessage];
            }
                break;
            default:
                break;
        }
    }
    /// 发送状态变更通知
    if (offlinemsg.completed) {
        [[LMConnectIMChater sharedManager] publishConnectState:LMSocketConnectStateConnected];
    }
}

- (void)deviceTokenUnbind:(Command *)command {
    CommandStauts *status = [CommandStauts parseFromData:command.detail error:nil];
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (status.status != 0) {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, nil);
        }
    } else {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, [NSError errorWithDomain:@"Undingfail" code:-1 userInfo:nil]);
        }
    }
}

- (void)deviceTokenBind:(Command *)command {
    
}

- (void)friendRequest:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    /// 代表添加好友请求的回执
    if (sendComModel) {
        switch (command.errNo) {
            case 3:
            case 1: {
                if (sendComModel.callBack) {
                    sendComModel.callBack(nil,[NSError errorWithDomain:@"" code:command.errNo userInfo:nil]);
                }
            }
                break;
            default:
                if (sendComModel.callBack) {
                    sendComModel.callBack(nil,nil);
                }
                break;
        }
    } else {
        /// 代表收到好友请求
        ReceiveFriendRequest *receveRequest = [ReceiveFriendRequest parseFromData:command.detail error:nil];
        if (sendComModel.callBack) {
            sendComModel.callBack(receveRequest,nil);
        }
    }
}


- (void)friendList:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    SyncRelationship *syncFriend = (SyncRelationship *)sendComModel.requestData;
    if ([syncFriend.version isEqualToString:@"0"]) {
        SyncUserRelationship *syncRalation = [SyncUserRelationship parseFromData:command.detail error:nil];
        if (sendComModel.callBack) {
            sendComModel.callBack(syncRalation, nil);
        }
    } else {
        ChangeRecords *changes = [ChangeRecords parseFromData:command.detail error:nil];
        if (sendComModel.callBack) {
            sendComModel.callBack(changes, nil);
        }
    }
}



- (void)acceptRequest:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    switch (command.errNo) {
        case 1: //msg: "ACCEPT ERROR"
        {
            NSError *error = [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil];
            if (sendComModel.callBack) {
                sendComModel.callBack(nil, error);
            }
        }
            break;
            
        case 4: //OVER TIME
        {
            NSError *error = [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil];
            if (sendComModel.callBack) {
                sendComModel.callBack(nil, error);
            }
        }
            break;
        default:
        {
            FriendListChange *listChange = [FriendListChange parseFromData:command.detail error:nil];
            /// 有请求代表回执
            if (sendComModel.callBack) {
                sendComModel.callBack(listChange.change.userInfo, nil);
            }
        }
            break;
    }
}

- (void)deleteUser:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    FriendListChange *listChange = [FriendListChange parseFromData:command.detail error:nil];
    if (command.errNo > 0) {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil ,[NSError errorWithDomain:command.msg code:command.errNo userInfo:nil]);
        }
    } else {
        if (sendComModel.callBack) {
            sendComModel.callBack(listChange.change.userInfo,nil);
        }
    }
}

- (void)setUserInfo:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (sendComModel.callBack) {
        sendComModel.callBack(nil, nil);
    }
}

- (void)groupInfoChange:(Command *) command{
    GroupChange *groupChange = [GroupChange parseFromData:command.detail error:nil];
    NSLog(@"groupChange %@",groupChange);
}

- (void)syncBadgeNumber:(Command *)command {
    
}

- (void)createSession:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (sendComModel.callBack) {
        sendComModel.callBack(nil, nil);
    }
}

- (void)sessionMute:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (sendComModel.callBack) {
        sendComModel.callBack(nil, nil);
    }
}

- (void)deleteSession:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (sendComModel.callBack) {
        sendComModel.callBack(nil, nil);
    }
}


- (void)urlTransfer:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (command.errNo == 0) {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, nil);
        }
    } else {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil]);
        }
    }
}

- (void)urlRedpacket:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (command.errNo == 0) {
        ExternalRedPackageInfo *redPackgeinfo = [ExternalRedPackageInfo parseFromData:command.detail error:nil];
        if (sendComModel.callBack) {
            sendComModel.callBack(redPackgeinfo, nil);
        }
    } else {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil]);
        }
    }
}

- (void)recommandNointeret:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    NOInterest *noInterest = (NOInterest *)sendComModel.requestData;
    if (sendComModel.callBack) {
        if (command.errNo > 0) {
            sendComModel.callBack(nil, [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil]);
        } else {
            sendComModel.callBack(noInterest.uid, nil);
        }
    }
}

- (void)uploadChatCookieAck:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    if (command.errNo == 0) {
        /// 保存
        [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession = sendComModel.sendMsg.chatCookie;
        
        /// 保存登录用户的chatcookie
        [[LMConnectIMChater sharedManager].chatSessionManager updateLoginUserChatSession:[LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession];
        
        /// 保存过期时间
        [[LMConnectIMChater sharedManager].chatSessionManager addOrUpdateChatUserSession:sendComModel.sendMsg.cookieData uid:[LMConnectIMChater sharedManager].chatSessionManager.connectUid];
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, nil);
        }
    } else {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil]);
        }
    }
}

- (void)userChatCookie:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommandMessages valueForKey:command.msgId];
    FriendChatCookie *requestChatCookie = (FriendChatCookie *)sendComModel.requestData;
    //friend did not report Chatcookie
    if (command.errNo == 5) {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, nil);
        }
    } else {
        ChatCookie *chatCookie = [ChatCookie parseFromData:command.detail error:nil];
        if ([LMEncryptKit verfiySign:chatCookie.sign signedData:[chatCookie.data_p.data hash256String] pubkey:requestChatCookie.pubkey]) {
            
            /// 保存好友会话session cookie
            [[LMConnectIMChater sharedManager].chatSessionManager addOrUpdateChatUserSession:chatCookie.data_p uid:requestChatCookie.uid];
            
            if (sendComModel.callBack) {
                sendComModel.callBack(chatCookie.data_p,nil);
            }
        } else {
            if (sendComModel.callBack) {
                sendComModel.callBack(nil,[NSError errorWithDomain:@"sign error" code:10 userInfo:nil]);
            }
        }
    }
}

- (void)loginOnNewPhoneUploadChatCookie:(Command *)command {
    [[LMConnectIMChater sharedManager] uploadCookieWithComplete:^(id data, NSError *error) {
        
    }];
}


@end


@implementation SendCommandModel

@end
