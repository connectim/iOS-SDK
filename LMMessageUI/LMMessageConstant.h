//
//  LMMessageConstant.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#ifndef LMMessageConstant_h
#define LMMessageConstant_h

typedef NS_ENUM(NSUInteger, LMMessageType) {
    /**
     *  unknow
     */
    LMMessageTypeNotFound = 0,
    /**
     *  text
     */
    LMMessageTypeText = 1,
    /**
     *  audio
     */
    LMMessageTypeAudio = 2,
    /**
     *  photo
     */
    LMMessageTypeImage = 3,
    
    /**
     *  video
     */
    LMMessageTypeVideo = 4,
    /**
     *  gif
     */
    LMMessageTypeGif = 5,
    /**
     *  time cell
     */
    LMMessageTypeTime = 8,
    
    /**
     *  open or close snapchat
     */
    LMMessageTypeSnapChat = 11,
    
    /**
     *  read ack
     */
    LMMessageTypeSnapChatReadedAck = 12,
    
    /**
     *  receipt
     */
    LMMessageTypePayReceipt = 14,
    
    
    /**
     *  transfer
     */
    LMMessageTypeTransfer = 15,
    
    /**
     *  luckypackage
     */
    LMMessageTypeRedEnvelope = 16,
    
    /**
     *  location
     */
    LMMessageTypeMapLocation = 17,
    
    /**
     *  namecard
     */
    LMMessageTypeNameCard = 18,
    /**
     *  tip cell
     */
    LMMessageTypeTip = 19,
    
    /**
     *  secure tip cell
     */
    LMMessageTypeSecureTip = 21,
    /**
     *
     */
    LMMessageTypeInviteToGroup = 23,
    
    /**
     *  reviewd group
     */
    LMMessageTypeApplyToJoinGroup = 24,
    /**
     *  wallet link
     */
    LMMessageTypeLink = 25,
    LMMessageTypeConnectGroupRviewed = 101,
    LMMessageTypeConnectAnnouncement = 102,
};


typedef NS_ENUM(NSInteger, LMLinkMsgType) {
    LMLinkMsgTypeOuterPacket = 0,
    LMLinkMsgTypeOuterTransfer,
    LMLinkMsgTypeOuterCollection,
    LMLinkMsgTypeOuterOther,
};

typedef NS_ENUM(NSUInteger,LMTransferMessageType) {
    LMTransferMessageTypeInnerSingle = 0,
    LMTransferMessageTypeInnerGroup,
    LMTransferMessageTypeOuterURL,
};

typedef NS_ENUM(NSUInteger, LMChatType) {
    LMChatTypePeer = 0,
    LMChatTypeGroup,
    LMChatTypeSystem,
};

typedef NS_ENUM(NSUInteger,LMMessageTipType) {
    LMMessageTipTypeNormal = 0,
    LMMessageTipTypeGrabRULLuckyPackage,
    LMMessageTipTypeLuckyPackageSender_Reciver,
    LMMessageTipTypePaymentReciver_Payer,
    LMMessageTipTypeNoFriend,
    LMMessageTipTypeNotInGroup,
    LMMessageTipTypeSeedButRejected,
    LMMessageTipTypeGroupReviewResp,
};


typedef NS_ENUM(NSInteger,LMBarButtonType) {
    LMBarButtonTypePanel = 0,
    LMBarButtonTypeEmoji,
    LMBarButtonTypeVoice,
};

typedef NS_ENUM(NSInteger,LMBarButtonStatus) {
    LMBarButtonStatusNormal = 0,
    LMBarButtonStatusKeyboard,
};


typedef NS_ENUM(NSUInteger, LMMessageStatus) {
    LMMessageStatusFailed = 0,
    LMMessageStatusSending,
    LMMessageStatusSuccess,
    LMMessageStatusNotInGroup,
    LMMessageStatusRejected,
};

typedef NS_ENUM(NSUInteger, LMChatEcdhKeySecurityLevelType) {
    LMChatEcdhKeySecurityLevelTypeNomarl = 0,
    LMChatEcdhKeySecurityLevelTypeHalfRandom,
    LMChatEcdhKeySecurityLevelTypeRandom,
};


#define LMMessageMeunCopy @"copy"
#define LMMessageMeunReweet @"reweet"
#define LMMessageMeunDelete @"delete"
#define LMMessageMeunSave @"save"


#define MSGInPutbarHeight 48
#define MSGInExtensionHeight 200

#define MSGAvatarHeight 40

#define MSGMsgMaxWidth (kScreenWidth - 4 * MSGAvatarHeight)
#define MSGMaxImageMsgWH (kScreenWidth / 2)
#define MSGMaxTextMsgW (kScreenWidth - 3.5 * MSGAvatarHeight)

#define MSGCellMargin 8
#define MSGBubbleHorn 8


// 字体大小
#define MSGTitleFont 17
#define MSGSubFont 14
#define MSGTipFont 14

#define MSGLinkURLName @"msg_url"
#define MSGLinkEmailName @"msg_email"
#define MSGLinkPhoneName @"msg_phone"
#define MSGDetailName @"msg_detail"
#define MSGNotRelationAddName @"not_rela_add"
#define MSGUpdateAppName @"update_app"

// 基本配色
#define MSGChatBackColor [UIColor colorWithHexString:@"F5F5F5"]
#define MSGBackContentColor [UIColor colorWithHexString:@"C0C0C0"]
#define MSGBlueColor [UIColor colorWithHexString:@"007AFF"]
#define MSGHighlightColor [UIColor colorWithHexString:@"F5F5F5"]

#endif /* LMMessageConstant_h */
