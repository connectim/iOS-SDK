//
//  LMIMMessageHandler.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/28.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMIMMessageHandler.h"
#import "Message.pbobjc.h"
#import "LMMessageTool.h"
#import "LMConnectIMChater.h"
#import "LMMessageAdapter.h"
#import "LMEncryptKit.h"

@implementation LMIMMessageHandler

+ (void)handldOfflineMessage:(Message *)msg {
    [self handldMessage:msg offlineMsg:YES];
}

+ (void)handldMessage:(Message *)msg {
    [self handldMessage:msg offlineMsg:NO];
}

+ (void)handldMessage:(Message *)msg offlineMsg:(BOOL)offlineMsg {
    switch (msg.extension) {
        case BM_IM_MESSAGE_ACK_EXT: {
            LMMessage *chatMsg = [LMMessageAdapter decodeMessageWithMassagePost:msg.body];
            if (chatMsg) {
                ReadReceiptMessage *read = (ReadReceiptMessage *) chatMsg.msgContent;
                MessageDidRead *msgDidRead = [MessageDidRead new];
                msgDidRead.msgId = read.messageId;
                msgDidRead.msgOwer = chatMsg.msgOwer;
                [[LMConnectIMChater sharedManager] reciveMessageDidRead:@[msgDidRead]];
            }
            /// 离线消息不需要回执
            if (!offlineMsg) {
                [[LMConnectIMChater sharedManager] sendOnlineAck:chatMsg.msgId type:0];
            }
        }
            break;
        case BM_IM_EXT: {
            [self handleIMMessage:msg.body offlineMsg:offlineMsg];
        }
            break;
        case BM_IM_SEND_GROUPINFO_EXT: {
            [self handleCreateGroupMessage:msg.body offlineMsg:offlineMsg];
        }
            break;
        case BM_IM_GROUPMESSAGE_EXT: {
            [self handleGroupMessage:msg.body offlineMsg:offlineMsg];
        }
            break;
        case BM_IM_UNARRIVE_EXT:
        case BM_IM_NO_RALATIONSHIP_EXT: {
            [[LMMessageSendManager sharedManager] messageRejectedMessage:msg.body];
        }
            break;
        case BM_SERVER_NOTE_EXT: {
            [[LMConnectIMChater sharedManager] reciveTransactionNotice:msg.body];
        }
            break;
        case BM_IM_ROBOT_EXT: {
            [self handleSystemMessage:msg.body offlineMsg:offlineMsg];
        }
            break;
        default:
            break;
    }
}

+ (void)handleIMMessage:(MessagePost *)msgPost offlineMsg:(BOOL)offlineMsg {
    LMMessage *chatMsg = [LMMessageAdapter decodeMessageWithMassagePost:msgPost];
    /// 保存消息
    [[[LMConnectIMChater sharedManager] messageDBManager] saveMessage:chatMsg];
    if (chatMsg) {
        [[LMConnectIMChater sharedManager] reciveMessage:@[chatMsg]];
    }
    /// 离线消息不需要回执
    if (!offlineMsg) {
        [[LMConnectIMChater sharedManager] sendOnlineAck:msgPost.msgData.chatMsg.msgId type:0];
    }
}

+ (void)handleGroupMessage:(MessagePost *)msgPost offlineMsg:(BOOL)offlineMsg {
    /// 获取群组会话的ECDHKey
    NSString *ECDHKey = nil;
    LMMessage *chatMsg = [LMMessageAdapter decodeMessageWithMassagePost:msgPost groupECDH:ECDHKey];
    /// 保存消息
    [[[LMConnectIMChater sharedManager] messageDBManager] saveMessage:chatMsg];
    if (chatMsg) {
        [[LMConnectIMChater sharedManager] reciveMessage:@[chatMsg]];
    }
    /// 离线消息不需要回执
    if (!offlineMsg) {
        [[LMConnectIMChater sharedManager] sendOnlineAck:msgPost.msgData.chatMsg.msgId type:0];
    }
}

+ (void)handleSystemMessage:(MSMessage *)sysMsg offlineMsg:(BOOL)offlineMsg {
    LMMessage *chatMsg = [LMMessageAdapter packSystemMessage:sysMsg];
    /// 保存消息
    [[[LMConnectIMChater sharedManager] messageDBManager] saveMessage:chatMsg];
    if (chatMsg) {
        [[LMConnectIMChater sharedManager] reciveMessage:@[chatMsg]];
    }
    /// 离线消息不需要回执
    if (!offlineMsg) {
        [[LMConnectIMChater sharedManager] sendOnlineAck:sysMsg.msgId type:0];
    }
}

+ (void)handleCreateGroupMessage:(MessagePost *)msgPost offlineMsg:(BOOL)offlineMsg {
    NSData *data = [LMMessageTool decodeGcmDataWithEmptySaltEcdhKey:[LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:msgPost.pubKey] GcmData:msgPost.msgData.chatMsg.cipherData havePlainData:YES];
    if (data.length > 0) {
        CreateGroupMessage *groupMessage = [CreateGroupMessage parseFromData:data error:nil];
        [[LMConnectIMChater sharedManager] reciveCreateGroupData:@[groupMessage]];
    }
    /// 离线消息不需要回执
    if (!offlineMsg) {
        [[LMConnectIMChater sharedManager] sendOnlineAck:msgPost.msgData.chatMsg.msgId type:0];
    }
}

@end
