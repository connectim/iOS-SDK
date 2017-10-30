//
//  LMMessageLayout.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYKit/YYKit.h>
#import "LMMessage.h"
#import "LMUserInfo.h"

@interface LMMessageLayout : NSObject

@property (nonatomic ,strong) LMMessage *chatMessage;
@property (nonatomic ,strong) LMUserInfo *sender;
@property (nonatomic ,strong) NSData *ECDHKey;

@property (nonatomic ,assign) CGFloat msgContentWidth;
@property (nonatomic ,assign) CGFloat msgContentHeight;
@property (nonatomic ,assign) CGFloat rowHeight;
@property (nonatomic ,strong) YYTextLayout *msgSenderNameLayout;
@property (nonatomic ,copy) NSString *sendAvatar;

//文本
@property (nonatomic ,strong) YYTextLayout *textMsgLayout;

@property (nonatomic ,strong) NSMutableArray *meuns;

@property (nonatomic ,strong) UIImage *msgImage; ///图片 地图 视频封面

/// 安全提示
@property (nonatomic ,strong) YYTextLayout *secureTipLayout;


/// 阅后即焚提示文字
@property (nonatomic ,strong) YYTextLayout *snapChatTipLayout;

/// 提示文字
@property (nonatomic ,strong) YYTextLayout *tipLayout;

/// 地图
@property (nonatomic ,strong) YYTextLayout *mapAddressLayout;

/// 视频
@property (nonatomic ,strong) YYTextLayout *videoTimeLayout;
@property (nonatomic ,strong) YYTextLayout *videoSizeLayout;
@property (nonatomic ,assign) BOOL videoDownloaded;
@property (nonatomic ,strong) NSURL *videoURL;

/// 链接
@property (nonatomic ,strong) YYTextLayout *websiteTitleLayout;
@property (nonatomic ,strong) YYTextLayout *websiteDescLayout;


/// 语音
@property (nonatomic ,strong) YYTextLayout *voiceTimeLayout;

/// 红包 收款 转账 邀请群组 审核 名片。。。
@property (nonatomic ,strong) YYTextLayout *commentsLayout;
@property (nonatomic ,strong) YYTextLayout *rightStatusLayout;
@property (nonatomic ,strong) YYTextLayout *leftStatusLayout;

- (instancetype)initWithMessage:(LMMessage *)message sender:(LMUserInfo *)sender;
- (void)layout;

@end
