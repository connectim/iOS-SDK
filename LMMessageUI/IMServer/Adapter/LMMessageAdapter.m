//
//  LMMessageAdapter.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageAdapter.h"
#import "LMMessageTool.h"
#import "NSString+Hex.h"
#import "LMEncryptKit.h"
#import "LMConnectIMChater.h"
#import "NSData+Hex.h"

@implementation LMMessageAdapter

+ (LMMessage *)decodeMessageWithMassagePost:(MessagePost *)msgPost groupECDH:(NSString *)groupECDH {
    NSData *data = [LMMessageTool decodeGcmDataWithEcdhKey:[groupECDH lmHexToData] GcmData:msgPost.msgData.chatMsg.cipherData havePlainData:NO];
    LMMessage *chatMessage = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
    return chatMessage;
}

+ (LMMessage *)decodeMessageWithMassagePost:(MessagePost *)msgPost {
    LMMessage *chatMessageInfo = nil;
    LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
    if (msgPost.msgData.chatSession.pubKey.length > 0 &&
            msgPost.msgData.chatSession.salt.length == 64 &&
            msgPost.msgData.chatSession.ver.length == 64) {
        securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
    } else if (msgPost.msgData.chatSession.pubKey.length > 0 &&
            msgPost.msgData.chatSession.salt.length == 64 &&
            msgPost.msgData.chatSession.ver.length == 0) {
        securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
    }
    switch (securityLevel) {
        case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
            NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:msgPost.msgData.chatSession.pubKey];
            ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:msgPost.msgData.chatSession.salt];
            NSData *data = [LMMessageTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:msgPost.msgData.chatMsg.cipherData havePlainData:NO];
            chatMessageInfo = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
        }
            break;
        case LMChatEcdhKeySecurityLevelTypeNomarl: {
            NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:msgPost.msgData.chatMsg.from];
            ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[LMMessageTool get64ZeroData]];
            NSData *data = [LMMessageTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:msgPost.msgData.chatMsg.cipherData havePlainData:NO];
            chatMessageInfo = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
        }
            break;
        case LMChatEcdhKeySecurityLevelTypeRandom: {
            
            NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPrivkey publicKey:msgPost.msgData.chatSession.pubKey];
            ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[msgPost.msgData.chatSession.ver orxWithData:msgPost.msgData.chatSession.salt]];
            NSData *data = [LMMessageTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:msgPost.msgData.chatMsg.cipherData havePlainData:NO];
            chatMessageInfo = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
            if (!data) {
                chatMessageInfo = [self createDecodeFailedTipMessageWithMassagePost:msgPost];
            }
        }
            break;
        default:
            break;
    }
    return chatMessageInfo;
}

+ (LMMessage *)createDecodeFailedTipMessageWithMassagePost:(MessagePost *)msgPost {
    LMMessage *chatMessage = [self makeNotifyMessageWithMessageOwer:msgPost.msgData.chatMsg.to content:NSLocalizedString(@"Chat One message failed to decrypt", nil) noteType:0 ext:nil];
    return chatMessage;
}

+ (LMMessage *)packSystemMessage:(MSMessage *)sysMsg {
    LMMessage *chatMessage = [[LMMessage alloc] init];
    chatMessage.msgType = sysMsg.category;
    chatMessage.createTime = [NSDate date];
    chatMessage.msgId = sysMsg.msgId;
    chatMessage.msgOwer = kSystemIdendifier;
    chatMessage.from = kSystemIdendifier;
    chatMessage.chatType = ChatType_ConnectSystem;
    chatMessage.status = LMMessageStatusSuccess;
    switch (sysMsg.category) {
        case LMMessageTypeText: {
            TextMessage *textMsg = [TextMessage parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = textMsg;
        }
            break;
        case LMMessageTypeAudio: {
            VoiceMessage *voiceMsg = [VoiceMessage parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = voiceMsg;
        }
            break;
        case LMMessageTypeImage: {
            PhotoMessage *imageMsg = [PhotoMessage parseFromData:sysMsg.body error:nil];
            if (imageMsg.imageWidth == 0) {
                imageMsg.imageWidth = AUTO_WIDTH(200);
            }
            if (imageMsg.imageHeight == 0) {
                imageMsg.imageHeight = AUTO_WIDTH(250);
            }
            chatMessage.msgContent = imageMsg;
        }
            break;
        case LMMessageTypeVideo: {
            
        }
            break;
        case LMMessageTypeMapLocation: {
            
        }
            break;
        case LMMessageTypeGif: {
            
        }
            break;
        case LMMessageTypeTransfer: {
            SystemTransferPackage *sysTransfer = [SystemTransferPackage parseFromData:sysMsg.body error:nil];
            chatMessage.msgType = LMMessageTypeTransfer;
            if (sysTransfer) {
                TransferMessage *transfer = [TransferMessage new];
                transfer.transferType = 3;
                transfer.amount = sysTransfer.amount;
                transfer.hashId = sysTransfer.txid;
                transfer.tips = sysTransfer.tips;
                chatMessage.msgContent = transfer;
            } else {
                chatMessage.msgType = LMMessageTypeNotFound;
            }
        }
            break;
        case LMMessageTypeRedEnvelope: //luckypackage
        {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
            NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
            int currentVer = [[versionNum stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            if (currentVer < 6) {
                chatMessage.msgType = LMMessageTypeNotFound;
            } else {
                chatMessage.msgType = LMMessageTypeRedEnvelope;
                SystemRedPackage *redPackMsg = [SystemRedPackage parseFromData:sysMsg.body error:nil];
                if (redPackMsg) {
                    LuckPacketMessage *luck = [LuckPacketMessage new];
                    luck.luckyType = 2;
                    luck.tips = redPackMsg.tips;
                    luck.hashId = redPackMsg.hashId;
                    luck.amount = redPackMsg.amount;
                    chatMessage.msgContent = redPackMsg;
                } else {
                    chatMessage.msgType = LMMessageTypeNotFound;
                }
            }
        }
            break;
        case LMMessageTypeConnectGroupRviewed: //group reviewed
        {
            Reviewed *reviewed = [Reviewed parseFromData:sysMsg.body error:nil];
            /// 发起申请表示用户不在群组中
            
            ReviewedStatus *reviewedStatus = [ReviewedStatus new];
            reviewedStatus.review = reviewed;
            reviewedStatus.newaccept = YES;
            reviewedStatus.refused = NO;
            chatMessage.msgType = LMMessageTypeApplyToJoinGroup;
            chatMessage.msgContent = reviewedStatus;
        }
            break;
        case 102: //announcement
        {
            Announcement *announcement = [Announcement parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = announcement;
        }
            break;
        case 103://luckypackage garb tips
        {
            chatMessage.msgType = LMMessageTypeTip;
            SystemRedpackgeNotice *repackNotict = [SystemRedpackgeNotice parseFromData:sysMsg.body error:nil];
            NSString *tips = [NSString stringWithFormat:NSLocalizedString(@"Chat opened Lucky Packet of", nil),repackNotict.receiver.username,NSLocalizedString(@"Chat You", nil)];
            NotifyMessage *notify = [self makeNotifyMessageWithTips:tips ext:repackNotict.hashid notifyType:LMMessageTipTypeGrabRULLuckyPackage];
            chatMessage.msgContent = notify;
        }
            break;

        case 104://group apply refuse or accepy tips
        {
            ReviewedResponse *repackNotict = [ReviewedResponse parseFromData:sysMsg.body error:nil];
            NotifyMessage *notify = [self makeNotifyMessageWithTips:[NSString stringWithFormat:@"%@/%@",repackNotict.name,repackNotict.identifier] ext:repackNotict.success?@"1":@"0" notifyType:LMMessageTipTypeGroupReviewResp];
            chatMessage.msgType = LMMessageTypeTip;
            chatMessage.msgContent = notify;
        }
            break;
        case 105://phone number change
        {
            UpdateMobileBind *nameBind = [UpdateMobileBind parseFromData:sysMsg.body error:nil];
            chatMessage.msgType = LMMessageTypeText;
            TextMessage *text = [self makeTextWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Chat Your Connect ID will no longer be linked with mobile number", nil), nameBind.username]];
            chatMessage.msgContent = text;
        }
            break;
        case 106: //dismiss group note
        {
            RemoveGroup *dismissGroup = [RemoveGroup parseFromData:sysMsg.body error:nil];
            NSString *tips = [NSString stringWithFormat:NSLocalizedString(@"Chat Group has been disbanded", nil), dismissGroup.name];
            NotifyMessage *notify = [self makeNotifyNormalMessageWithTips:tips];
            chatMessage.msgType = LMMessageTypeTip;
            chatMessage.msgContent = notify;
        }
            break;
        case 200: {//outer address transfer to self
            AddressNotify *addressNot = [AddressNotify parseFromData:sysMsg.body error:nil];
            TransferMessage *transfer = [self makeTransferWithHashId:addressNot.txId transferType:3 amount:addressNot.amount tips:nil];
            chatMessage.msgType = LMMessageTypeTransfer;
            chatMessage.msgContent = transfer;
        }
            break;
        default:
            break;
    }
    return chatMessage;
}

+ (GPBMessage *)packageChatMsg:(ChatMessage *)chatMsg groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg {
    MessageData *messageData = [[MessageData alloc] init];
    /// chat msg
    messageData.chatMsg = chatMsg;
    
    /// chat session
    ChatSession *chatSession = [[ChatSession alloc] init];
    messageData.chatSession = chatSession;

    switch (chatMsg.chatType) {
        case ChatType_Private:
        {
            ChatCookieData *reciverChatCookie = [[LMConnectIMChater sharedManager].chatSessionManager chatUserSessionWithUid:chatMsg.to];
            LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
            BOOL reciverChatCookieExpire = reciverChatCookie.expired > [[NSDate date] timeIntervalSince1970];
            if (reciverChatCookie && [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession && !reciverChatCookieExpire) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
            } else if ((!reciverChatCookie || reciverChatCookieExpire)
                       && [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
            }
            switch (securityLevel) {
                case LMChatEcdhKeySecurityLevelTypeRandom: {
                    chatSession.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPubKey;
                    chatSession.salt = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt;
                    chatSession.ver = reciverChatCookie.salt;
                    NSString * privkey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPrivkey;
                    NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:privkey publicKey:reciverChatCookie.chatPubKey];
                    // Salt or
                    NSData *exoData = [[LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt orxWithData:reciverChatCookie.salt];
                    ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
                    chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:ecdhKey];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeNomarl: {
                    NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:chatMsg.to];
                    ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[LMMessageTool get64ZeroData]];
                    chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:ecdhKey];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
                    
                    chatSession.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPubKey;
                    chatSession.salt = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt;
                    
                    NSString * privkey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPrivkey;
                    NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:privkey publicKey:chatMsg.to];
                    // Extended
                    ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt];
                    chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:ecdhKey];
                }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case ChatType_Groupchat:{
            chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:[groupEcdh lmHexToData]];
        }
            break;
            
        case ChatType_ConnectSystem:{
            MSMessage *msMessage = [[MSMessage alloc] init];
            msMessage.msgId = [LMMessageTool generateMessageId];
            msMessage.body = originMsg.data;
            msMessage.category = chatMsg.msgType;
            IMTransferData *imTransferData = [LMMessageTool makeTransferDataWithExtensionPass_Data:msMessage.data];
            return imTransferData;
        }
            break;
            
        default:
            break;
    }

    NSString *sign = [LMEncryptKit signData:messageData.data.lmHexString privkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    messagePost.msgData = messageData;
    messagePost.sign = sign;
    
    return messagePost;

}


+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg msgId:(NSString *)msgId {
    MessageData *messageData = [[MessageData alloc] init];
    
    /// chat msg
    ChatMessage *chatMsg = [[ChatMessage alloc] init];
    chatMsg.from = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    chatMsg.to = to;
    chatMsg.msgType = msgType;
    chatMsg.ext = ext;
    chatMsg.msgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMsg.chatType = chatType;
    chatMsg.msgId = msgId;
    messageData.chatMsg = chatMsg;
    
    /// chat session
    ChatSession *chatSession = [[ChatSession alloc] init];
    messageData.chatSession = chatSession;
    
    
    return messageData;
}

+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg {
    return [self packageMessageDataWithTo:to chatType:chatType msgType:msgType ext:ext groupEcdh:groupEcdh cipherData:originMsg msgId:[LMMessageTool generateMessageId]];
}


+ (LMMessage *)chatMessageInfoWithChatMsg:(ChatMessage *)chatMsg originMsg:(GPBMessage *)originMsg{
    LMMessage *chatMessageInfo = [LMMessage new];
    chatMessageInfo.msgId = chatMsg.msgId;
    switch (chatMsg.chatType) {
        case ChatType_Private:
        {
            chatMessageInfo.msgOwer = chatMsg.from;
            chatMessageInfo.from = chatMsg.from;
        }
            break;
        case ChatType_Groupchat:
        {
            chatMessageInfo.msgOwer = chatMsg.to;
            chatMessageInfo.from = chatMsg.from;
        }
            break;
            
        case ChatType_ConnectSystem:
        {
            chatMessageInfo.msgOwer = kSystemIdendifier;
            chatMessageInfo.from = chatMsg.from;
        }
            break;
            
        default:
            break;
    }
    chatMessageInfo.createTime = [NSDate dateWithTimeIntervalSince1970:chatMsg.msgTime / 1000];
    chatMessageInfo.chatType = chatMsg.chatType;
    chatMessageInfo.msgType = chatMsg.msgType;
    chatMessageInfo.msgContent = originMsg;
    chatMessageInfo.status = LMMessageStatusSuccess;
 
    return chatMessageInfo;
}

+ (MessageData *)packageChatMessageInfo:(LMMessage *)chatMessageInfo ext:(id)ext groupEcdh:(NSString *)groupEcdh {
    MessageData *messageData = [[MessageData alloc] init];
    /// chat msg
    ChatMessage *chatMsg = [[ChatMessage alloc] init];
    chatMsg.from = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    chatMsg.to = chatMessageInfo.msgOwer;
    chatMsg.msgType = chatMessageInfo.msgType;
    chatMsg.ext = ext;
    chatMsg.msgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMsg.msgId = chatMessageInfo.msgId;
    chatMsg.chatType = chatMessageInfo.chatType;
    messageData.chatMsg = chatMsg;
    GPBMessage *originMsg = (GPBMessage *)chatMessageInfo.msgContent;
    switch (chatMsg.chatType) {
        case ChatType_Private:
        {
            ChatCookieData *reciverChatCookie = [[LMConnectIMChater sharedManager].chatSessionManager chatUserSessionWithUid:chatMsg.to];
            LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
            BOOL reciverChatCookieExpire = reciverChatCookie.expired < [[NSDate date] timeIntervalSince1970];
            if (reciverChatCookie && [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession && !reciverChatCookieExpire) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
            } else if ((!reciverChatCookie || reciverChatCookieExpire)
                       && [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
            }
            switch (securityLevel) {
                case LMChatEcdhKeySecurityLevelTypeRandom: {
                    /// chat session
                    ChatSession *chatSession = [[ChatSession alloc] init];
                    messageData.chatSession = chatSession;
                    chatSession.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPubKey;
                    chatSession.salt = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt;
                    chatSession.ver = reciverChatCookie.salt;
                    NSString * privkey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPrivkey;
                    NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:privkey publicKey:reciverChatCookie.chatPubKey];
                    // Salt or
                    NSData *exoData = [[LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt orxWithData:reciverChatCookie.salt];
                    ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
                    chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:ecdhKey];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeNomarl: {
                    NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:chatMsg.to];
                    ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[LMMessageTool get64ZeroData]];
                    chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:ecdhKey];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
                    
                    /// chat session
                    ChatSession *chatSession = [[ChatSession alloc] init];
                    messageData.chatSession = chatSession;
                    chatSession.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPubKey;
                    chatSession.salt = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt;
                    
                    NSString * privkey = [LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.chatPrivkey;
                    NSData *ecdhKey = [LMEncryptKit getECDHkeyWithPrivkey:privkey publicKey:chatMsg.to];
                    // Extended
                    ecdhKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[LMConnectIMChater sharedManager].chatSessionManager.loginUserChatSession.salt];
                    chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:ecdhKey];
                }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case ChatType_Groupchat:{
            chatMsg.cipherData = [LMMessageTool encodeData:originMsg.data needPlainData:NO withECDHKey:[groupEcdh lmHexToData]];
        }
            break;
        case ChatType_ConnectSystem:{
            MSMessage *msMessage = [[MSMessage alloc] init];
            msMessage.msgId = [LMMessageTool generateMessageId];
            msMessage.body = originMsg.data;
            msMessage.category = chatMsg.msgType;
            IMTransferData *imTransferData = [LMMessageTool makeTransferDataWithExtensionPass_Data:msMessage.data];
            return imTransferData;
        }
            break;
        default:
            break;
    }
    return messageData;
}

+ (GPBMessage *)parseDataWithData:(NSData *)data msgType:(int)msgType {
    GPBMessage *msgContent = nil;
    switch (msgType) {
        case LMMessageTypeText:
        {
            msgContent = [TextMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeMapLocation: {
            msgContent = [LocationMessage parseFromData:data error:nil];
        }
            break;
            
        case LMMessageTypeAudio:
        {
            msgContent = [VoiceMessage parseFromData:data error:nil];
        }
            break;
            
        case LMMessageTypeVideo:
        {
            msgContent = [VideoMessage parseFromData:data error:nil];
        }
            break;
            
        case LMMessageTypeImage:
        {
            msgContent = [PhotoMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeGif: {
            msgContent = [EmotionMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypePayReceipt:
        {
            msgContent = [PaymentMessage parseFromData:data error:nil];
        }
            break;
            
        case LMMessageTypeTransfer:
        {
            msgContent = [TransferMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeRedEnvelope: {
            msgContent = [LuckPacketMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeNameCard: {
            msgContent = [CardMessage parseFromData:data error:nil];
        }
            break;
            
        case LMMessageTypeLink: {
            msgContent = [WebsiteMessage parseFromData:data error:nil];
        }
            break;
        case 102:{
            msgContent = [Announcement parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeApplyToJoinGroup:
        {
            msgContent = [ReviewedStatus parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeSnapChat:
        {
            msgContent = [DestructMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeSnapChatReadedAck:
        {
            msgContent = [ReadReceiptMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeTip:
        {
            msgContent = [NotifyMessage parseFromData:data error:nil];
        }
            break;
        case LMMessageTypeInviteToGroup:{
            msgContent = [JoinGroupMessage parseFromData:data error:nil];
        }
            break;
            
        default:
            break;
    }
    return msgContent;
}

+ (BOOL)checkMessageData:(MessageData *)msgData {
    ChatMessage *chatMsg = msgData.chatMsg;
    if (chatMsg.msgId.length == 0) {
        NSLog(@"消息ID为空");
        return NO;
    }
    
    if (chatMsg.to.length == 0) {
        NSLog(@"接受方未赋值");
        return NO;
    }
    
    if (chatMsg.from == 0) {
        NSLog(@"发送方未赋值");
        return NO;
    }
    
    if (chatMsg.cipherData.aad.length == 0) {
        NSLog(@"消息aad为空");
        return NO;
    }
    
    if (chatMsg.cipherData.iv.length == 0) {
        NSLog(@"消息iv为空");
        return NO;
    }
    
    if (chatMsg.cipherData.tag.length == 0) {
        NSLog(@"消息tag为空");
        return NO;
    }
    
    if (chatMsg.cipherData.ciphertext.length == 0) {
        NSLog(@"消息ciphertext为空");
        return NO;
    }
    
    if (chatMsg.msgTime == 0) {
        NSLog(@"消息发送时间为空");
        return NO;
    }
    
    return YES;
}


+ (LMMessage *)chatMessageInfoWithMessageOwer:(NSString *)msgOwer messageType:(LMMessageType)messageType sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [[LMMessage alloc] init];
    chatMessage.msgId = [LMMessageTool generateMessageId];
    chatMessage.msgOwer = msgOwer;
    chatMessage.createTime = [NSDate date];
    chatMessage.msgType = messageType;
    chatMessage.from = sender;
    chatMessage.chatType = chatType;
    chatMessage.status = LMMessageStatusSending;
    return chatMessage;
}

+ (TextMessage *)makeTextWithMessageText:(NSString *)msgText {
    TextMessage *text = [TextMessage new];
    text.content = msgText;
    return text;
}

+ (LMMessage *)makeTextChatMessageWithMessageText:(NSString *)msgText msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeText sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeTextWithMessageText:msgText];
    return chatMessage;
}

+ (EmotionMessage *)makeEmotionWithGifID:(NSString *)gifId {
    EmotionMessage *emotion = [EmotionMessage new];
    emotion.content = gifId;
    return emotion;
}

+ (LMMessage *)makeEmotionChatMessageWithGifID:(NSString *)gifId  msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeGif sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeEmotionWithGifID:gifId];
    return chatMessage;
}


+ (PaymentMessage *)makeRecipetWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize {
    PaymentMessage *payment = [PaymentMessage new];
    payment.hashId = hashId;
    payment.paymentType = paymentType;
    payment.amount = amount;
    payment.tips = tips;
    payment.memberSize = memberSize;
    return payment;
}

+ (LMMessage *)makeRecipetChatMessageWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypePayReceipt sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeRecipetWithHashId:hashId paymentType:paymentType amount:amount tips:tips memberSize:memberSize];
    return chatMessage;
}

+ (TransferMessage *)makeTransferWithHashId:(NSString *)hashId transferType:(int)transferType amount:(int64_t)amount tips:(NSString *)tips {
    TransferMessage *transfer = [TransferMessage new];
    transfer.amount = amount;
    transfer.transferType = transferType;
    transfer.tips = tips;
    transfer.hashId = hashId;
    return transfer;
}

+ (LMMessage *)makeTransferChatMessageWithHashId:(NSString *)hashId transferType:(LMTransferMessageType)transferType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeTransfer sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeTransferWithHashId:hashId transferType:transferType amount:amount tips:tips];
    return chatMessage;
}

+ (LuckPacketMessage *)makeLuckyPackageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips {
    LuckPacketMessage *luck = [LuckPacketMessage new];
    luck.hashId = hashId;
    luck.tips = tips;
    luck.amount = amount;
    luck.luckyType = luckType;
    
    return luck;
}

+ (LMMessage *)makeLuckyPackageChatMessageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeRedEnvelope sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeLuckyPackageWithHashId:hashId luckType:luckType amount:amount tips:tips];
    return chatMessage;
}


+ (CardMessage *)makeCardWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid {
    CardMessage *card = [CardMessage new];
    card.uid = uid;
    card.avatar = avatar;
    card.username = username;
    return card;
}

+ (LMMessage *)makeCardChatMessageWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeNameCard sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeCardWithUsername:username avatar:avatar uid:uid];
    return chatMessage;
}


+ (WebsiteMessage *)makeWebSiteWithURL:(NSString *)url walletLinkType:(LMLinkMsgType)walletLinkType {
    WebsiteMessage *website = [WebsiteMessage new];
    website.URL = url;
    switch (walletLinkType) {
        case LMLinkMsgTypeOuterTransfer: {
            website.title = NSLocalizedString(@"Wallet Wallet Out Send Share", nil);
            website.subtitle = NSLocalizedString(@"Wallet Click to recive payment", nil);
        }
            break;
        case LMLinkMsgTypeOuterPacket: {
            website.title = NSLocalizedString(@"Wallet Send a lucky packet", nil);
            website.subtitle = NSLocalizedString(@"Wallet Click to open lucky packet", nil);
        }
            break;
        case LMLinkMsgTypeOuterCollection: {
            website.title = NSLocalizedString(@"Wallet Send the payment connection", nil);
            website.subtitle = NSLocalizedString(@"Wallet Click to transfer bitcoin", nil);
        }
            break;
        default:
            break;
    }
    return website;
}

+ (LMMessage *)makeWebSiteChatMessageWithURL:(NSString *)url walletLinkType:(LMLinkMsgType)walletLinkType msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeLink sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeWebSiteWithURL:url walletLinkType:walletLinkType];
    return chatMessage;
}

+ (LocationMessage *)makeLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address {
    LocationMessage *location = [LocationMessage new];
    location.latitude = latitude;
    location.longitude = longitude;
    location.address = address;
    return location;
}

+ (LMMessage *)makeLocationChatMessageWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeMapLocation sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeLocationWithLatitude:latitude longitude:longitude address:address];
    return chatMessage;
}

+ (VoiceMessage *)makeVoiceWithSize:(int)size url:(NSString *)url{
    VoiceMessage *voice = [VoiceMessage new];
    voice.timeLength = size;
    voice.URL = url;
    return voice;
}

+ (LMMessage *)makeVoiceChatMessageWithSize:(int)size url:(NSString *)url msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeAudio sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeVoiceWithSize:size url:url];
    return chatMessage;
}

+ (VideoMessage *)makeVideoWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover {
    VideoMessage *video = [VideoMessage new];
    video.size = size;
    video.imageWidth = videoCoverW;
    video.imageHeight = videoCoverH;
    video.timeLength = time;
    video.URL = videoUrl;
    video.cover = videoCover;
    
    return video;
}

+ (LMMessage *)makeVideoChatMessageWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeVideo sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeVideoWithSize:size time:time videoCoverW:videoCoverW videoCoverH:videoCoverH videoUrl:videoUrl videoCover:videoCover];
    return chatMessage;
}

+ (PhotoMessage *)makePhotoWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage {
    PhotoMessage *photo = [PhotoMessage new];
    photo.imageWidth = ImageW;
    photo.imageHeight = imageH;
    photo.thum = thumImage;
    photo.URL = oriImage;
    return photo;
}

+ (LMMessage *)makePhotoChatMessageWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeImage sender:sender chatType:chatType];
    chatMessage.msgContent = [self makePhotoWithImageW:ImageW imageH:imageH oriImage:oriImage thumImage:thumImage];
    return chatMessage;
}

+ (ReadReceiptMessage *)makeReadReceiptWithMsgId:(NSString *)msgId {
    ReadReceiptMessage *readReceipt = [ReadReceiptMessage new];
    readReceipt.messageId = msgId;
    return readReceipt;
}

+ (LMMessage *)makeReadReceiptChatMessageWithMsgId:(NSString *)msgId msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeSnapChatReadedAck sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeReadReceiptWithMsgId:msgId];
    return chatMessage;
}

+ (LMMessage *)makeDestructChatMessageWithTime:(int)time msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeSnapChat sender:sender chatType:0];
    chatMessage.status = LMMessageStatusSuccess;
    chatMessage.msgContent = [self makeDestructWithTime:time];
    return chatMessage;
}

+ (DestructMessage *)makeDestructWithTime:(int)time {
    DestructMessage *destruct = [DestructMessage new];
    destruct.time = time;
    
    return destruct;
}

+ (NotifyMessage *)makeNotifyMessageWithTips:(NSString *)tips ext:(NSString *)ext notifyType:(LMMessageTipType)notifyType{
    NotifyMessage *notify = [self makeNotifyNormalMessageWithTips:tips];
    notify.extion = ext;
    notify.notifyType = notifyType;
    return notify;
}

+ (NotifyMessage *)makeNotifyNormalMessageWithTips:(NSString *)tips {
    NotifyMessage *notify = [NotifyMessage new];
    notify.content = tips;
    return notify;
}

+ (LMMessage *)makeNotifyMessageWithMessageOwer:(NSString *)messageOwer content:(NSString *)content noteType:(LMMessageTipType)noteType ext:(id)ext {
    LMMessage *chatMessage = [[LMMessage alloc] init];
    chatMessage.msgId = [LMMessageTool generateMessageId];
    chatMessage.msgOwer = messageOwer;
    chatMessage.createTime = [NSDate date];
    chatMessage.msgType = LMMessageTypeTip;
    chatMessage.status = LMMessageStatusSuccess;
    chatMessage.msgContent = [self makeNotifyMessageWithTips:content ext:ext notifyType:noteType];
    return chatMessage;
}

+ (LMMessage *)makeJoinGroupChatMessageWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token msgOwer:(NSString *)msgOwer sender:(NSString *)sender {
    LMMessage *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:LMMessageTypeInviteToGroup sender:sender chatType:0];
    chatMessage.msgContent = [self makeJoinGroupWithAvatar:avatar groupId:groupId groupName:groupName token:token];
    return chatMessage;
}

+ (JoinGroupMessage *)makeJoinGroupWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token{
    JoinGroupMessage *joinGroup = [JoinGroupMessage new];
    joinGroup.avatar = avatar;
    joinGroup.groupId = groupId;
    joinGroup.groupName = groupName;
    joinGroup.token = token;
    return joinGroup;
}

+ (void)packageChatMessageInfo:(LMMessage *)chatMessageInfo snapTime:(int)snapTime {
    switch (chatMessageInfo.msgType) {
            
        case LMMessageTypeText:
        {
            TextMessage *text = (TextMessage *)chatMessageInfo.msgContent;
            text.snapTime = snapTime;
        }
            break;
            
        case LMMessageTypeAudio:
        {
            VoiceMessage *voice = (VoiceMessage *)chatMessageInfo.msgContent;
            voice.snapTime = snapTime;
        }
            break;
            
        case LMMessageTypeVideo:
        {
            VideoMessage *video = (VideoMessage *)chatMessageInfo.msgContent;
            video.snapTime = snapTime;
        }
            break;
            
        case LMMessageTypeImage:
        {
            PhotoMessage *photo = (PhotoMessage *)chatMessageInfo.msgContent;
            photo.snapTime = snapTime;
        }
            break;
            
        case LMMessageTypeGif: {
            EmotionMessage *emotion = (EmotionMessage *)chatMessageInfo.msgContent;
            emotion.snapTime = snapTime;
        }
            break;
        default:
            break;
    }
}


+ (ChatMessage *)chatMsgWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext {
    /// chat msg
    ChatMessage *chatMsg = [[ChatMessage alloc] init];
    chatMsg.from = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    chatMsg.to = to;
    chatMsg.msgType = msgType;
    chatMsg.ext = ext;
    chatMsg.msgId = [LMMessageTool generateMessageId];
    chatMsg.msgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMsg.chatType = chatType;
    
    return chatMsg;
}


+ (LMMessage *)chatMsgInfoWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType msgContent:(GPBMessage *)msgContent {
    LMMessage *messageInfo = [[LMMessage alloc] init];
    messageInfo.msgId = [LMMessageTool generateMessageId];
    messageInfo.msgType = msgType;
    messageInfo.createTime = [NSDate date];
    messageInfo.msgOwer = to;
    messageInfo.status = LMMessageStatusSuccess;
    messageInfo.msgContent = msgContent;
    messageInfo.chatType = chatType;
    messageInfo.from = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    
    return messageInfo;
}


+ (BOOL)checkRichtextUploadStatuts:(LMMessage *)msg {
    switch (msg.msgType) {
        case LMMessageTypeAudio: {
            VoiceMessage *voice = (VoiceMessage *)msg.msgContent;
            return voice.URL.length;
        }
            break;
        case LMMessageTypeImage: {
            PhotoMessage *photo = (PhotoMessage *)msg.msgContent;
            return photo.URL.length && photo.thum.length;
        }
            break;
        case LMMessageTypeMapLocation:{
            LocationMessage *location = (LocationMessage *)msg.msgContent;
            return location.screenShot.length;
        }
            break;
        case LMMessageTypeVideo:{
            VideoMessage *video = (VideoMessage *)msg.msgContent;
            return video.URL.length && video.cover.length;
        }
            break;
        default:
            break;
    }
    return YES;
}


@end
