//
//  LMMessageAdapter.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.pbobjc.h"
#import "LMMessage.h"

@interface LMMessageAdapter : NSObject

+ (LMMessage *)decodeMessageWithMassagePost:(MessagePost *)msgPost;

+ (LMMessage *)decodeMessageWithMassagePost:(MessagePost *)msgPost groupECDH:(NSString *)groupECDH;

+ (LMMessage *)packSystemMessage:(MSMessage *)sysMsg;

+ (GPBMessage *)packageChatMsg:(ChatMessage *)chatMsg groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg;

+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg;

+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg msgId:(NSString *)msgId;

+ (MessageData *)packageChatMessageInfo:(LMMessage *)chatMessageInfo ext:(id)ext groupEcdh:(NSString *)groupEcdh;

+ (GPBMessage *)parseDataWithData:(NSData *)data msgType:(int)msgType;

+ (BOOL)checkMessageData:(MessageData *)msgData;


+ (LMMessage *)makeTextChatMessageWithMessageText:(NSString *)msgText msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (TextMessage *)makeTextWithMessageText:(NSString *)msgText ;

+ (LMMessage *)makeEmotionChatMessageWithGifID:(NSString *)gifId  msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (EmotionMessage *)makeEmotionWithGifID:(NSString *)gifId ;


+ (LMMessage *)makeRecipetChatMessageWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (PaymentMessage *)makeRecipetWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize ;


+ (LMMessage *)makeTransferChatMessageWithHashId:(NSString *)hashId transferType:(LMTransferMessageType)transferType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (TransferMessage *)makeTransferWithHashId:(NSString *)hashId transferType:(int)transferType amount:(int64_t)amount tips:(NSString *)tips ;


+ (LMMessage *)makeLuckyPackageChatMessageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (LuckPacketMessage *)makeLuckyPackageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips ;

+ (LMMessage *)makeCardChatMessageWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (CardMessage *)makeCardWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid ;


+ (LMMessage *)makeWebSiteChatMessageWithURL:(NSString *)url walletLinkType:(LMLinkMsgType)walletLinkType msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (WebsiteMessage *)makeWebSiteWithURL:(NSString *)url walletLinkType:(LMLinkMsgType)walletLinkType;


+ (LMMessage *)makeLocationChatMessageWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (LocationMessage *)makeLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address ;


+ (LMMessage *)makeVoiceChatMessageWithSize:(int)size url:(NSString *)url msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (VoiceMessage *)makeVoiceWithSize:(int)size url:(NSString *)url;


+ (LMMessage *)makeVideoChatMessageWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (VideoMessage *)makeVideoWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover;


+ (LMMessage *)makePhotoChatMessageWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (PhotoMessage *)makePhotoWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage;

+ (ReadReceiptMessage *)makeReadReceiptWithMsgId:(NSString *)msgId;

+ (LMMessage *)makeDestructChatMessageWithTime:(int)time msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (DestructMessage *)makeDestructWithTime:(int)time;

+ (LMMessage *)makeNotifyMessageWithMessageOwer:(NSString *)messageOwer content:(NSString *)content noteType:(LMMessageTipType)noteType ext:(id)ext;
+ (NotifyMessage *)makeNotifyNormalMessageWithTips:(NSString *)tips;
+ (NotifyMessage *)makeNotifyMessageWithTips:(NSString *)tips ext:(NSString *)ext notifyType:(LMMessageTipType)notifyType;

+ (LMMessage *)makeJoinGroupChatMessageWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (JoinGroupMessage *)makeJoinGroupWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token;


+ (BOOL)checkRichtextUploadStatuts:(LMMessage *)msg;

@end
