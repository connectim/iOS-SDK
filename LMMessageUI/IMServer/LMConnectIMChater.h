//
//  LMConnectIMChater.h
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LMMessage.h"
#import "LMChatSessionManager.h"
#import "TCPConnection.h"
#import "LMCommandSendManager.h"
#import "LMMessageSendManager.h"
#import "MessageDBManageDelegate.h"

@protocol LMConnectIMChaterDelegate <NSObject>

/// 交易通知
- (void)transactionNoticeDidReceive:(NoticeMessage *)notice;

/// 接收到消息
- (void)messagesDidReceive:(NSArray <LMMessage *> *)msgs;

/// 消息已读
- (void)messagesDidRead:(NSArray <MessageDidRead *> *)messageIds;

/// 群组创建消息
- (void)createGroupDidReceive:(NSArray<CreateGroupMessage *> *)inviteGroups;

@end

@interface LMConnectIMChater : TCPConnection

+ (instancetype)sharedManager;

/// config server host and port
@property(nonatomic, copy) NSString *host;
@property(nonatomic, assign) int32_t *port;

/// chat session manager
@property(nonatomic, strong) LMChatSessionManager *chatSessionManager;

- (id <MessageDBManageDelegate>)messageDBManager;
- (void)configMessageDBManager:(id<MessageDBManageDelegate>)msgDbManager;

/// start im server
- (void)startIMServer;

/// send online ack
- (void)sendOnlineAck:(NSString *)msgID type:(int32_t)type;

/// send offline ack
- (void)sendOfflineAck:(NSString *)msgID type:(int32_t)type;

/// Batch ack
- (void)sendOfflineMessagesAck:(NSArray *)msgIds;

/// send message did read
- (void)messageDidReadWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete;

/// send peer / system message
- (void)sendP2PMessageInfo:(LMMessage *)chatMsg progress:(void (^)(NSString *to, NSString *msgId, CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete;

/// send group message with group ECDHKEY
- (void)sendGroupChatMessageInfo:(LMMessage *)msg groupECDHKey:(NSString *)groupECDHKey progress:(void (^)(NSString *to, NSString *msgId, CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete;

/// update user remark / common
- (void)updateUserRemark:(NSString *)remark common:(BOOL)common userId:(NSString *)uid complete:(SocketCallback)complete;

/// delete friend
- (void)deleteFriendWithUid:(NSString *)uid complete:(SocketCallback)complete;

/// send request to stranger
- (void)sendRequestToUid:(NSString *)uid source:(int)source message:(NSString *)requestMessage complete:(SocketCallback)complete;

/// receive url transfer with token
- (void)reciveMoneyWithToken:(NSString *)token complete:(SocketCallback)complete;

/// receive url luckypackage with token
- (void)openRedPacketWithToken:(NSString *)token complete:(SocketCallback)complete;

/// fetch firend list
- (void)friendListWithVersion:(NSString *)version comlete:(SocketCallback)complete;

/// accept some connect user request
- (void)acceptFriendRequest:(NSString *)uid source:(int)source comlete:(SocketCallback)complete;

/// fetch friend chatcookie ,pubkey used to sign.
- (void)friendChatCookieWithUid:(NSString *)uid pubkey:(NSString *)pubkey complete:(SocketCallback)complete;

/// sync badge number
- (void)syncBadgeNumber:(int)badgeNumber;

/// set recomand user no more interest
- (void)recommandFriendNoInterestWithUid:(NSString *)uid comlete:(SocketCallback)complete;

/// logout and resign apns token
- (void)resignDeviceToken:(NSString *)deviceToken complete:(SocketCallback)complete;

/// register device token for apns
- (void)signDeviceToken:(NSString *)deviceToken complete:(SocketCallback)complete;

/// set chat session mute or not mute
- (void)sessionMute:(BOOL)mute uid:(NSString *)uid complete:(SocketCallback)complete;

/// upload a new chatcookie
- (void)uploadCookieWithComplete:(SocketCallback)complete;

/// add receive message delegate
- (void)addReciveMessageDelegate:(id <LMConnectIMChaterDelegate>)delegate;

/// remove receive message delegate
- (void)removeReciveMessageDelegate:(id <LMConnectIMChaterDelegate>)delegate;

/// receive trancation notice
- (void)reciveTransactionNotice:(NoticeMessage *)notice;

/// receive message
- (void)reciveMessage:(NSArray <LMMessage *> *)messages;

/// receive create group message
- (void)reciveCreateGroupData:(NSArray <CreateGroupMessage *> *)createGroups;

/// receive message did read
- (void)reciveMessageDidRead:(NSArray <MessageDidRead *> *)msgDidReads;


@end
