//
//  LMMessageBaseCell.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMessageLayout.h"
#import "LMMessageConstant.h"
#import "LMMsgBaseContentView.h"

@protocol LMMessageActionDelegate <NSObject>

/// 点击图片
- (void)imageDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 视频
- (void)videoDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 名片
- (void)cardDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 红包
- (void)luckyPackageDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 收款
- (void)receiptDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 转账
- (void)transferDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 位置
- (void)locationDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 网页链接分享消息
- (void)webUrlDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 蓝色文字
- (void)highlightTextDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout userInfo:(NSDictionary *)userInfo;

/// 群组申请
- (void)groupInviteDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 进群审核
- (void)groupReviewedDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 系统公告
- (void)connectAnnouncementDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 头像点击
- (void)headAvatarDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 重新发送
- (void)resendButtonDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 保存到相册
- (void)saveMessageToAlbumDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 复制
- (void)copyMessageDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 删除
- (void)deleteMessageDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

/// 转发
- (void)retweetMessageDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout;

@end

@interface LMMessageBaseCell : UITableViewCell

/// layout
@property (nonatomic ,strong) LMMessageLayout *msgLayout;
@property (nonatomic ,weak) id<LMMessageActionDelegate>delegate;

@end
