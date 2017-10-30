//
//  LMConnectIMChater.m
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMConnectIMChater.h"
#import "LMChatMsgUploadManager.h"
#import "LMMessageAdapter.h"
#import "LMMessageTool.h"
#import "LMEncryptKit.h"
#import "NSString+Hex.h"
#import "NSData+Hex.h"
#import "LMIMMessageHandler.h"
#import "LMCommandAdapter.h"
#import "NSData+Hash.h"

@interface LMConnectIMChater ()

@property(nonatomic) dispatch_queue_t messageSendQueue;

@property(nonatomic, strong) NSHashTable *reciveMessageObservers;

/// 心跳
@property(nonatomic, copy) BOOL (^HeartBeatBlock)();

@property (nonatomic ,strong) id <MessageDBManageDelegate> msgDbManager;

@end

@implementation LMConnectIMChater

- (dispatch_queue_t)messageSendQueue {
    if (!_messageSendQueue) {
        _messageSendQueue = dispatch_queue_create("_imserver_message_sender_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _messageSendQueue;
}

- (NSHashTable *)reciveMessageObservers {
    if (!_reciveMessageObservers) {
        _reciveMessageObservers = [NSHashTable weakObjectsHashTable];
    }
    return _reciveMessageObservers;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static LMConnectIMChater *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[LMConnectIMChater alloc] init];
    });
    return instance;
}

- (LMChatSessionManager *)chatSessionManager {
    return [LMChatSessionManager shareManager];
}

- (id <MessageDBManageDelegate>)messageDBManager {
    return self.msgDbManager;
}

- (void)configMessageDBManager:(id<MessageDBManageDelegate>)msgDbManager {
    _msgDbManager = msgDbManager;
}

- (void)startIMServer {
    [self start];
}


/// 发送消息和命令
- (void)messageDidReadWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete {
    /// 业务层
    GPBMessage *originMsg = [LMMessageAdapter makeReadReceiptWithMsgId:msgId];
    MessageData *messageData = [LMMessageAdapter packageMessageDataWithTo:to chatType:ChatType_Private msgType:LMMessageTypeSnapChatReadedAck ext:nil groupEcdh:nil cipherData:originMsg];

    dispatch_async(self.messageSendQueue, ^{
        /// 发送数据
        MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
        //aad sending message to queue
        [[LMMessageSendManager sharedManager] addSendingMessage:messageData.chatMsg originContent:originMsg callBack:complete];
        BOOL result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_MESSAGE_ACK_EXT];
        if (!result) {
            [[LMMessageSendManager sharedManager] messageSendFailedMessageId:messageData.chatMsg.msgId];
        }
    });
}

- (void)sendP2PMessageInfo:(LMMessage *)msg progress:(void (^)(NSString *to, NSString *msgId, CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete {
    ChatCookieData *reciverChatCookie = [self.chatSessionManager chatUserSessionWithUid:msg.msgOwer];
    if (reciverChatCookie) {
        /// Socket层
        MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:msg ext:nil groupEcdh:nil];
        if ([LMMessageAdapter checkRichtextUploadStatuts:msg]) {
            /// 更新会话
            /// 发送数据
            dispatch_async(self.messageSendQueue, ^{
                [[LMMessageSendManager sharedManager] addSendingMessage:messageData.chatMsg originContent:msg.msgContent callBack:complete];
                BOOL result = NO;
                switch (msg.chatType) {
                    case LMChatTypePeer: {
                        MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
                        result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_EXT];
                    }
                        break;
                    case LMChatTypeGroup: {
                        MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
                        result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_GROUPMESSAGE_EXT];
                    }
                    case LMChatTypeSystem: {
                        MSMessage *msMessage = [[MSMessage alloc] init];
                        msMessage.msgId = msg.msgId;
                        GPBMessage *content = (GPBMessage *) msg.msgContent;
                        msMessage.body = content.data;
                        msMessage.category = msg.msgType;
                        IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:msMessage.data];
                        result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_ROBOT_EXT];
                    }
                    default:
                        break;
                }
                
                /// 没有网络发送失败
                if (!result) {
                    [[LMMessageSendManager sharedManager] messageSendFailedMessageId:messageData.chatMsg.msgId];
                }
            });
        } else {
            NSData *mainData = nil;
            NSData *minorData = nil;
            switch (msg.msgType) {
                case LMMessageTypeAudio: {
                    NSString *amrFilePath = @"";
                    mainData = [NSData dataWithContentsOfFile:amrFilePath];
                }
                    break;
                case LMMessageTypeImage: {
                    NSString *originPath = @"";
                    NSString *thumbImageNamePath = @"";
                    minorData = [NSData dataWithContentsOfFile:thumbImageNamePath];
                    mainData = [NSData dataWithContentsOfFile:originPath];
                }
                    break;
                case LMMessageTypeVideo: {
                    NSString *videoPath = @"";
                    minorData = nil;
                    mainData = [NSData dataWithContentsOfFile:videoPath];
                }
                    break;
                case LMMessageTypeMapLocation: {
                    NSString *imagePath = @"";
                    mainData = [NSData dataWithContentsOfFile:imagePath];
                }
                    break;
                default:
                    break;
            }
            if (mainData) {
                NSData *ECDHKey = nil;
                if (msg.chatType == LMChatTypePeer) {
                    ECDHKey = [LMEncryptKit getECDHkeyWithPrivkey:self.chatSessionManager.connectPrikey
                                                        publicKey:msg.msgOwer];
                }
                /// 上传富文本消息
                [[LMChatMsgUploadManager shareManager] uploadMainData:mainData minorData:minorData encryptECDH:ECDHKey to:msg.msgOwer msgId:msg.msgId chatType:msg.chatType originMsg:msg.msgContent progress:progress complete:^(GPBMessage *originMsg, NSString *to, NSString *msgId, NSError *error) {
                    /// 更新消息
                    if (error) {
                        if (complete) {
                            
                        }
                    } else {
                        /// 更新消息
                        
                        /// 封装消息
                        
                        /// Socket层
                        
                        /// 更新会话
                        
                        /// 发送数据
                    }
                }];
            } else {
                if (complete) {
                    
                }
            }
        }
    } else {
        [self friendChatCookieWithUid:msg.msgOwer pubkey:msg.msgOwer complete:^(id data, NSError *error) {
            if (!error) {
                /// Socket层
                MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:msg ext:nil groupEcdh:nil];
                if ([LMMessageAdapter checkRichtextUploadStatuts:msg]) {
                    /// 更新会话
                    /// 发送数据
                    dispatch_async(self.messageSendQueue, ^{
                        [[LMMessageSendManager sharedManager] addSendingMessage:messageData.chatMsg originContent:msg.msgContent callBack:complete];
                        BOOL result = NO;
                        switch (msg.chatType) {
                            case LMChatTypePeer: {
                                MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
                                result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_EXT];
                            }
                                break;
                            case LMChatTypeGroup: {
                                MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
                                result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_GROUPMESSAGE_EXT];
                            }
                            case LMChatTypeSystem: {
                                MSMessage *msMessage = [[MSMessage alloc] init];
                                msMessage.msgId = msg.msgId;
                                GPBMessage *content = (GPBMessage *) msg.msgContent;
                                msMessage.body = content.data;
                                msMessage.category = msg.msgType;
                                IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:msMessage.data];
                                result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_ROBOT_EXT];
                            }
                            default:
                                break;
                        }
                        
                        /// 没有网络发送失败
                        if (!result) {
                            [[LMMessageSendManager sharedManager] messageSendFailedMessageId:messageData.chatMsg.msgId];
                        }
                    });
                } else {
                    NSData *mainData = nil;
                    NSData *minorData = nil;
                    switch (msg.msgType) {
                        case LMMessageTypeAudio: {
                            NSString *amrFilePath = @"";
                            mainData = [NSData dataWithContentsOfFile:amrFilePath];
                        }
                            break;
                        case LMMessageTypeImage: {
                            NSString *originPath = @"";
                            NSString *thumbImageNamePath = @"";
                            minorData = [NSData dataWithContentsOfFile:thumbImageNamePath];
                            mainData = [NSData dataWithContentsOfFile:originPath];
                        }
                            break;
                        case LMMessageTypeVideo: {
                            NSString *videoPath = @"";
                            minorData = nil;
                            mainData = [NSData dataWithContentsOfFile:videoPath];
                        }
                            break;
                        case LMMessageTypeMapLocation: {
                            NSString *imagePath = @"";
                            mainData = [NSData dataWithContentsOfFile:imagePath];
                        }
                            break;
                        default:
                            break;
                    }
                    if (mainData) {
                        NSData *ECDHKey = nil;
                        if (msg.chatType == LMChatTypePeer) {
                            ECDHKey = [LMEncryptKit getECDHkeyWithPrivkey:self.chatSessionManager.connectPrikey
                                                                publicKey:msg.msgOwer];
                        }
                        /// 上传富文本消息
                        [[LMChatMsgUploadManager shareManager] uploadMainData:mainData minorData:minorData encryptECDH:ECDHKey to:msg.msgOwer msgId:msg.msgId chatType:msg.chatType originMsg:msg.msgContent progress:progress complete:^(GPBMessage *originMsg, NSString *to, NSString *msgId, NSError *error) {
                            /// 更新消息
                            if (error) {
                                if (complete) {
                                    
                                }
                            } else {
                                /// 更新消息
                                
                                /// 封装消息
                                
                                /// Socket层
                                
                                /// 更新会话
                                
                                /// 发送数据
                            }
                        }];
                    } else {
                        if (complete) {
                            
                        }
                    }
                }
            } else {
                if (complete) {
                    
                }
            }
        }];
    }
}

- (void)sendGroupChatMessageInfo:(LMMessage *)msg groupECDHKey:(NSString *)groupECDHKey progress:(void (^)(NSString *to, NSString *msgId, CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete {
    /// Socket层
    MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:msg ext:nil groupEcdh:groupECDHKey];
    if ([LMMessageAdapter checkRichtextUploadStatuts:msg]) {
        /// 更新会话
        /// 发送数据
        dispatch_async(self.messageSendQueue, ^{
            [[LMMessageSendManager sharedManager] addSendingMessage:messageData.chatMsg originContent:msg.msgContent callBack:complete];
            BOOL result = NO;
            switch (msg.chatType) {
                case LMChatTypePeer: {
                    MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
                    result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_EXT];
                }
                    break;
                case LMChatTypeGroup: {
                    MessagePost *request = [LMMessageTool makeMessagePostWithMsgData:messageData];
                    result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_GROUPMESSAGE_EXT];
                }
                case LMChatTypeSystem: {
                    MSMessage *msMessage = [[MSMessage alloc] init];
                    msMessage.msgId = msg.msgId;
                    GPBMessage *content = (GPBMessage *) msg.msgContent;
                    msMessage.body = content.data;
                    msMessage.category = msg.msgType;
                    IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:msMessage.data];
                    result = [self sendData:request withType:BM_IM_TYPE extension:BM_IM_ROBOT_EXT];
                }
                default:
                    break;
            }

            /// 没有网络发送失败
            if (!result) {
                [[LMMessageSendManager sharedManager] messageSendFailedMessageId:messageData.chatMsg.msgId];
            }
        });
    } else {
        NSData *mainData = nil;
        NSData *minorData = nil;
        switch (msg.msgType) {
            case LMMessageTypeAudio: {
                NSString *amrFilePath = @"";
                mainData = [NSData dataWithContentsOfFile:amrFilePath];
            }
                break;
            case LMMessageTypeImage: {
                NSString *originPath = @"";
                NSString *thumbImageNamePath = @"";
                minorData = [NSData dataWithContentsOfFile:thumbImageNamePath];
                mainData = [NSData dataWithContentsOfFile:originPath];
            }
                break;
            case LMMessageTypeVideo: {
                NSString *videoPath = @"";
                minorData = nil;
                mainData = [NSData dataWithContentsOfFile:videoPath];
            }
                break;
            case LMMessageTypeMapLocation: {
                NSString *imagePath = @"";
                mainData = [NSData dataWithContentsOfFile:imagePath];
            }
                break;
            default:
                break;
        }
        if (mainData) {
            /// 上传富文本消息
            [[LMChatMsgUploadManager shareManager] uploadMainData:mainData minorData:minorData encryptECDH:groupECDHKey.lmHexToData to:msg.msgOwer msgId:msg.msgId chatType:msg.chatType originMsg:msg.msgContent progress:progress complete:^(GPBMessage *originMsg, NSString *to, NSString *msgId, NSError *error) {
                /// 更新消息
                if (error) {
                    if (complete) {

                    }
                } else {
                    /// 更新消息

                    /// 封装消息

                    /// Socket层

                    /// 更新会话

                    /// 发送数据
                }
            }];
        } else {
            if (complete) {

            }
        }
    }
}

- (void)updateUserRemark:(NSString *)remark common:(BOOL)common userId:(NSString *)uid complete:(SocketCallback)complete {
    SettingFriendInfo *setUser = [SettingFriendInfo new];
    setUser.uid = uid;
    setUser.common = common;
    setUser.remark = remark;
    [self sendCommandWithRequestData:setUser extension:BM_SET_FRIENDINFO_EXT complete:complete];
}

- (void)deleteFriendWithUid:(NSString *)uid complete:(SocketCallback)complete {
    RemoveRelationship *removeUser = [RemoveRelationship new];
    removeUser.uid = uid;
    [self sendCommandWithRequestData:removeUser extension:BM_DELETE_FRIEND_EXT complete:complete];
}

- (void)sendRequestToUid:(NSString *)uid source:(int)source message:(NSString *)requestMessage complete:(SocketCallback)complete {
    AddFriendRequest *addFriend = [AddFriendRequest new];
    addFriend.uid = uid;
    addFriend.source = source;
    addFriend.tips = requestMessage;
    [self sendCommandWithRequestData:addFriend extension:BM_NEWFRIEND_EXT complete:complete];
}

- (void)reciveMoneyWithToken:(NSString *)token complete:(SocketCallback)complete {
    ExternalBillingToken *billToken = [ExternalBillingToken new];
    billToken.token = token;
    [self sendCommandWithRequestData:billToken extension:BM_OUTER_TRANSFER_EXT complete:complete];
}

- (void)openRedPacketWithToken:(NSString *)token complete:(SocketCallback)complete {
    RedPackageToken *luckyToken = [RedPackageToken new];
    luckyToken.token = token;
    [self sendCommandWithRequestData:luckyToken extension:BM_OUTER_REDPACKET_EXT complete:complete];
}

- (void)friendListWithVersion:(NSString *)version comlete:(SocketCallback)complete {
    SyncRelationship *syncFriend = [SyncRelationship new];
    syncFriend.version = version;
    [self sendCommandWithRequestData:syncFriend extension:BM_FRIENDLIST_EXT complete:complete];
}

- (void)acceptFriendRequest:(NSString *)uid source:(int)source comlete:(SocketCallback)complete {
    AcceptFriendRequest *accept = [AcceptFriendRequest new];
    accept.uid = uid;
    accept.source = source;
    [self sendCommandWithRequestData:accept extension:BM_ACCEPT_NEWFRIEND_EXT complete:complete];
}

- (void)friendChatCookieWithUid:(NSString *)uid pubkey:(NSString *)pubkey complete:(SocketCallback)complete; {
    FriendChatCookie *friendCookie = [FriendChatCookie new];
    friendCookie.uid = uid;
    friendCookie.pubkey = pubkey;
    [self sendCommandWithRequestData:friendCookie extension:BM_FRIEND_CHAT_COOKIE_EXT complete:complete];
}

- (void)syncBadgeNumber:(int)badgeNumber {
    SyncBadge *sycnBadge = [SyncBadge new];
    sycnBadge.badge = badgeNumber;
    [self sendCommandWithRequestData:sycnBadge extension:BM_SYNCBADGENUMBER_EXT complete:nil];
}

- (void)recommandFriendNoInterestWithUid:(NSString *)uid comlete:(SocketCallback)complete {
    NOInterest *noInterest = [NOInterest new];
    noInterest.uid = uid;
    [self sendCommandWithRequestData:noInterest extension:BM_RECOMMADN_NOTINTEREST_EXT complete:complete];
}

- (void)resignDeviceToken:(NSString *)deviceToken complete:(SocketCallback)complete {
    DeviceToken *token = [DeviceToken new];
    token.apnsDeviceToken = deviceToken;
    token.pushType = @"APNS";
    [self sendCommandWithRequestData:token extension:BM_UNBINDDEVICETOKEN_EXT complete:complete];
}

- (void)signDeviceToken:(NSString *)deviceToken complete:(SocketCallback)complete {
    DeviceToken *deviceT = [[DeviceToken alloc] init];
    deviceT.apnsDeviceToken = deviceToken;
    deviceT.pushType = @"APNS";
    [self sendCommandWithRequestData:deviceT extension:BM_BINDDEVICETOKEN_EXT complete:complete];
}

- (void)sessionMute:(BOOL)mute uid:(NSString *)uid complete:(SocketCallback)complete {
    UpdateSession *muteSession = [UpdateSession new];
    muteSession.mute = mute;
    muteSession.uid = uid;
    [self sendCommandWithRequestData:muteSession extension:BM_SETMUTE_SESSION complete:complete];
}

- (void)uploadCookieWithComplete:(SocketCallback)complete {
    /// 本地会话Session
    ChatCacheCookie *chatCookie = [ChatCacheCookie new];
    chatCookie.chatPrivkey = [LMEncryptKit creatConnectIMPrivkey];
    chatCookie.chatPubKey = [LMEncryptKit connectIMPubkeyByPrikey:chatCookie.chatPrivkey];
    chatCookie.salt = [LMEncryptKit createRandom512bits];

    ChatCookieData *cookieData = [ChatCookieData new];
    cookieData.expired = [[NSDate date] timeIntervalSince1970] + 24 * 60 * 60;
    cookieData.chatPubKey = chatCookie.chatPubKey;
    cookieData.salt = chatCookie.salt;

    ChatCookie *cookie = [ChatCookie new];
    cookie.data_p = cookieData;
    cookie.sign = [LMEncryptKit signData:[cookieData.data hash256String] privkey:self.chatSessionManager.connectPrikey];

    CommandMessage *commandMsg = [LMCommandAdapter sendAdapterWithExtension:BM_UPLOAD_CHAT_COOKIE_EXT sendData:cookie];
    commandMsg.chatCookie = chatCookie;
    commandMsg.cookieData = cookieData;
    
    [[LMCommandSendManager sharedManager] addSendingCommandMessage:commandMsg originContent:cookie callBack:complete];
    BOOL result = [self sendData:commandMsg.transferData withType:BM_COMMAND_TYPE extension:commandMsg.commandExtension];
    if (!result) {
        /// 发送失败
        [[LMCommandSendManager sharedManager] sendCommandFailedWithCommandId:commandMsg.commandId];
    }
}


/// 接受消息
- (void)addReciveMessageDelegate:(id <LMConnectIMChaterDelegate>)delegate {
    [self.reciveMessageObservers addObject:delegate];
}

- (void)removeReciveMessageDelegate:(id <LMConnectIMChaterDelegate>)delegate {
    [self.reciveMessageObservers removeObject:delegate];
}

- (void)reciveTransactionNotice:(NoticeMessage *)notice {
    for (id <LMConnectIMChaterDelegate> delegate in self.reciveMessageObservers) {
        if ([delegate respondsToSelector:@selector(transactionNoticeDidReceive:)]) {
            [delegate transactionNoticeDidReceive:notice];
        }
    }
}

- (void)reciveMessage:(NSArray <LMMessage *> *)messages {
    for (id <LMConnectIMChaterDelegate> delegate in self.reciveMessageObservers) {
        if ([delegate respondsToSelector:@selector(messagesDidReceive:)]) {
            [delegate messagesDidReceive:messages];
        }
    }
}

- (void)reciveMessageDidRead:(NSArray <MessageDidRead *> *)msgDidReads {
    for (id <LMConnectIMChaterDelegate> delegate in self.reciveMessageObservers) {
        if ([delegate respondsToSelector:@selector(messagesDidRead:)]) {
            [delegate messagesDidRead:msgDidReads];
        }
    }
}

- (void)reciveCreateGroupData:(NSArray <CreateGroupMessage *> *)createGroups {
    for (id <LMConnectIMChaterDelegate> delegate in self.reciveMessageObservers) {
        if ([delegate respondsToSelector:@selector(createGroupDidReceive:)]) {
            [delegate createGroupDidReceive:createGroups];
        }
    }
}

#pragma mark - socket send data

- (void)sendCommandWithRequestData:(GPBMessage *)requestData extension:(unsigned char)extension complete:(SocketCallback)complete {
    CommandMessage *commandMsg = [LMCommandAdapter sendAdapterWithExtension:extension sendData:requestData];
    [[LMCommandSendManager sharedManager] addSendingCommandMessage:commandMsg originContent:requestData callBack:complete];
    BOOL result = [self sendData:commandMsg.transferData withType:BM_COMMAND_TYPE extension:commandMsg.commandExtension];
    if (!result) {
        /// 发送失败
        [[LMCommandSendManager sharedManager] sendCommandFailedWithCommandId:commandMsg.commandId];
    }
}

- (BOOL)sendData:(GPBMessage *)request withType:(unsigned char)type extension:(unsigned char)extension {
    Message *socketMsg = [[Message alloc] init];
    socketMsg.typechar = type;
    socketMsg.extension = extension;
    socketMsg.len = (int) [request data].length;
    socketMsg.body = [request data];
    /// 发送数据
    return [self sendMessage:socketMsg];
}

- (void)sendOnlineAck:(NSString *)msgID type:(int32_t)type {
    Ack *ack = [[Ack alloc] init];
    ack.msgId = msgID;
    ack.type = type;
    IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:ack.data];
    [self sendData:request withType:BM_ACK_TYPE extension:BM_ACK_BACK_EXT];
}

- (void)sendOfflineAck:(NSString *)msgID type:(int32_t)type {
    Ack *ack = [[Ack alloc] init];
    ack.msgId = msgID;
    ack.type = type;
    IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:ack.data];
    [self sendData:request withType:BM_ACK_TYPE extension:BM_ACK_OFFLIE_BACK_EXT];
}

- (void)sendOfflineMessagesAck:(NSArray *)msgIds {
    OfflineMsgAck *acks = [OfflineMsgAck new];
    acks.msgIdsArray = msgIds.mutableCopy;
    IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:acks.data];
    [self sendData:request withType:BM_ACK_TYPE extension:BM_MULT_ACK_EXT];
}

- (BOOL)sendMessage:(Message *)msg {
    if ((self.connectState & LMSocketConnectStateConnected) ||
            (self.connectState & LMSocketConnectStateAuthing) ||
            (self.connectState & LMSocketConnectStateUpdatingMessage)) {
        NSData *data = [msg pack];
        if (!data) {
            return NO;
        }
        [self write:data];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - socket revice data

- (BOOL)handleData:(NSData *)data message:(Message *)message {
    switch (message.typechar) {
        case BM_HANDSHAKE_TYPE:
            [self handleHandshakeWithMessage:message];
            break;
        case BM_IM_TYPE:
            [LMIMMessageHandler handldMessage:message];
            break;
        case BM_ACK_TYPE: {
            Ack *ack = (Ack *) message.body;
            [[LMMessageSendManager sharedManager] messageSendSuccessMessageId:ack.msgId];
        }
            break;
        case BM_COMMAND_TYPE:
            [[LMCommandSendManager sharedManager] receiveCommandMessage:message];
            break;
        case BM_CUTOFFINE_CONNECT_TYPE:

            break;
        case BM_HEARTBEAT_TYPE:
            [self pong];
            break;
        default:
            break;
    }
    return YES;
}

- (void)handleHandshakeWithMessage:(Message *)msg {
    switch (msg.extension) {
        case BM_HANDSHAKE_EXT: {
            [self handleAuthStatus:msg];
        }
            break;
        case BM_HANDSHAKEACK_EXT: {
            [self authSussecc:msg];
        }
            break;
        default:
            break;
    }
}

- (void)handleAuthStatus:(Message *)msg {
    IMResponse *response = (IMResponse *) msg.body;
    NSData *password = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:self.chatSessionManager.userServerECDH salt:[LMMessageTool get64ZeroData]];
    NSData *handAckData = [LMMessageTool decodeRequest:response ECDHKey:password];
    if (!handAckData || handAckData.length <= 0) {
        return;
    }
    NewConnection *conn = [NewConnection parseFromData:handAckData error:nil];
    NSData *saltData = [self.chatSessionManager.sendSalt orxWithData:conn.salt];

    NSData *passwordTem = [LMEncryptKit getECDHkeyWithPrivkey:self.chatSessionManager.randomPrivkey publicKey:[conn.pubKey lmHexString]];
    NSData *extensionPass = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:passwordTem salt:saltData];
    self.chatSessionManager.socketExtensionECDH = extensionPass;

    //upload device info
    NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
    DeviceInfo *deviceId = [[DeviceInfo alloc] init];
    deviceId.deviceId = uuid.UUIDString;
    deviceId.deviceName = [UIDevice currentDevice].name;
    deviceId.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    deviceId.uuid = @"12312";
    deviceId.cv = 1;
    ChatCookieData *chatCookieData = [self.chatSessionManager chatUserSessionWithUid:self.chatSessionManager.connectUid];
    if (chatCookieData) {
        deviceId.chatCookieData = chatCookieData;
    }
    
    IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:deviceId.data];
    [self sendData:request withType:BM_HANDSHAKE_TYPE extension:BM_HANDSHAKEACK_EXT];
}

- (void)authSussecc:(Message *)msg {
    __weak __typeof(&*self) weakSelf = self;
    self.HeartBeatBlock = ^{
        IMTransferData *request = [IMTransferData new];
        return [weakSelf sendData:request withType:BM_HEARTBEAT_TYPE extension:BM_HEARTBEAT_EXT];
    };
}

- (void)onConnect {
    self.connectState = LMSocketConnectStateAuthing;
    [self publishConnectState:self.connectState];

    self.chatSessionManager.randomPrivkey = [LMEncryptKit creatConnectIMPrivkey];
    self.chatSessionManager.randomPublickey = [LMEncryptKit connectIMPubkeyByPrikey:self.chatSessionManager.randomPrivkey];
    self.chatSessionManager.sendSalt = [LMEncryptKit createRandom512bits];

    NewConnection *conn = [[NewConnection alloc] init];
    conn.salt = self.chatSessionManager.sendSalt;
    conn.pubKey = [self.chatSessionManager.randomPublickey lmHexToData];

    IMRequest *request = [LMMessageTool makeRequestWithData:conn.data ECDHKey:self.chatSessionManager.userServerECDH];
    [self sendData:request withType:BM_HANDSHAKE_TYPE extension:BM_HANDSHAKE_EXT];
}

- (void)connecting {

}

- (BOOL)sendPing {
    NSLog(@"ping>>>>>");
    if (self.HeartBeatBlock) {
        return self.HeartBeatBlock();
    }
    return NO;
}

@end
