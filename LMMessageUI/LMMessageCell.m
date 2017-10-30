//
//  LMMessageCell.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/19.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageCell.h"
#import "LMMsgTextContentView.h"
#import "LMImageContentView.h"
#import "LMMsgVideoView.h"

@interface LMMessageCell ()

/// 发送者头像
@property (nonatomic ,strong) UIImageView *avatarImageView;

/// 发送者昵称
@property (nonatomic ,strong) YYLabel *senderNameLabel;

/// 消息内容
@property (nonatomic ,strong) LMMsgBaseContentView *msgContentView;

@property (nonatomic ,strong) UIButton *resendMsgBtn;

@property (nonatomic ,strong) UIActivityIndicatorView *sendIngMsgIndicator;

@end

@implementation LMMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.avatarImageView = [UIImageView new];
        self.avatarImageView.height = MSGAvatarHeight;
        self.avatarImageView.width = MSGAvatarHeight;
        self.avatarImageView.top = MSGCellMargin;
        self.avatarImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHeadAvatar)];
        [self.avatarImageView addGestureRecognizer:tap];
        [self.contentView addSubview:self.avatarImageView];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMsgContent)];
        [self.contentView addGestureRecognizer:longPress];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMeun) name:UIMenuControllerDidHideMenuNotification object:nil];
        
        self.senderNameLabel = [YYLabel new];
        [self.contentView addSubview:self.senderNameLabel];
        
        self.resendMsgBtn = [UIButton new];
        self.resendMsgBtn.size = CGSizeMake(30,30);
        [self.resendMsgBtn setImage:[UIImage imageNamed:@"msg_sendfailed"] forState:UIControlStateNormal];
        [self.resendMsgBtn addTarget:self action:@selector(resendMsg) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.resendMsgBtn];
        
        self.sendIngMsgIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.sendIngMsgIndicator.size = self.resendMsgBtn.size;
        [self.sendIngMsgIndicator hidesWhenStopped];
        [self.contentView addSubview:self.sendIngMsgIndicator];
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
    if (msgLayout.chatMessage.sendFromSelf) {
        self.avatarImageView.right = kScreenWidth - MSGCellMargin;
    } else {
        self.avatarImageView.left = MSGCellMargin;
    }
    [self.avatarImageView setImageWithURL:[NSURL URLWithString:msgLayout.sendAvatar] placeholder:nil];
    
    [self configMsgContentView];
    
    self.resendMsgBtn.centerY = msgLayout.rowHeight / 2.f;
    self.sendIngMsgIndicator.centerY = msgLayout.rowHeight / 2.f;
    if (msgLayout.msgSenderNameLayout &&
        !msgLayout.chatMessage.sendFromSelf) { // 需要发送者姓名
        self.senderNameLabel.textLayout = msgLayout.msgSenderNameLayout;
        self.senderNameLabel.size = msgLayout.msgSenderNameLayout.textBoundingSize;
        self.senderNameLabel.left = self.avatarImageView.right + MSGCellMargin;
        self.senderNameLabel.top = self.avatarImageView.top;
        self.resendMsgBtn.hidden = YES;
        self.msgContentView.top = self.senderNameLabel.bottom + MSGCellMargin;
        self.msgContentView.left = self.senderNameLabel.left;
    } else {
        self.senderNameLabel.textLayout = nil;
        self.senderNameLabel.size = CGSizeZero;
        if (msgLayout.chatMessage.sendFromSelf) {
            self.msgContentView.top = self.avatarImageView.top;
            self.msgContentView.right = self.avatarImageView.left - MSGCellMargin;
            self.resendMsgBtn.hidden = (msgLayout.chatMessage.status == LMMessageStatusSending ||
                                        msgLayout.chatMessage.status == LMMessageStatusSuccess);
            self.sendIngMsgIndicator.hidden = msgLayout.chatMessage.status != LMMessageStatusSending;
            if (!self.sendIngMsgIndicator.hidden) {
                [self.sendIngMsgIndicator startAnimating];
            }
            self.resendMsgBtn.right = self.msgContentView.left - MSGCellMargin;
            self.sendIngMsgIndicator.right = self.resendMsgBtn.right;
        } else {
            self.msgContentView.top = self.avatarImageView.top;
            self.msgContentView.left = self.avatarImageView.right + MSGCellMargin;
            self.resendMsgBtn.hidden = YES;
            self.sendIngMsgIndicator.hidden = YES;
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return self.msgLayout.meuns.count > 0;
}

- (void)resendMsg {
    if ([self.delegate respondsToSelector:@selector(resendButtonDidTap:msgLayout:)]) {
        [self.delegate resendButtonDidTap:self msgLayout:self.msgLayout];
    }
}

- (void)hideMeun {
    [self.msgContentView setHighlighted:NO animated:YES];
}

- (void)tapHeadAvatar {
    if ([self.delegate respondsToSelector:@selector(headAvatarDidTap:msgLayout:)]) {
        [self.delegate headAvatarDidTap:self msgLayout:self.msgLayout];
    }
}

- (void)longPressMsgContent {
    if (self.canBecomeFirstResponder) {
        [self becomeFirstResponder];
        UIMenuController *menu = [UIMenuController sharedMenuController];
        if (!menu.menuVisible) {
            [menu setTargetRect:self.msgContentView.frame inView:self];
            
            NSMutableArray *menuItems = [NSMutableArray array];
            if ([self.msgLayout.meuns containsObject:LMMessageMeunCopy]) {
                [menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyMsg:)]];
            }
            if ([self.msgLayout.meuns containsObject:LMMessageMeunReweet]) {
                [menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"转发" action:@selector(retweetMsg:)]];
            }
            if ([self.msgLayout.meuns containsObject:LMMessageMeunDelete]) {
                [menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteMsg:)]];
            }
            if ([self.msgLayout.meuns containsObject:LMMessageMeunSave]) {
                [menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"保存到相册" action:@selector(save:)]];
            }
            menu.menuItems = menuItems;
            [menu setMenuVisible:YES animated:YES];
            [self.msgContentView setHighlighted:YES animated:YES];
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copyMsg:)
        || action == @selector(retweetMsg:)
        || action == @selector(deleteMsg:)
        || action == @selector(save:)) {
        return YES;
    }
    return NO;
}

- (void)save:(id)sender {
    if ([self.delegate respondsToSelector:@selector(saveMessageToAlbumDidTap:msgLayout:)]) {
        [self.delegate saveMessageToAlbumDidTap:self msgLayout:self.msgLayout];
    }
}

- (void)copyMsg:(id)sender {
    if ([self.delegate respondsToSelector:@selector(copyMessageDidTap:msgLayout:)]) {
        [self.delegate copyMessageDidTap:self msgLayout:self.msgLayout];
    }
}

- (void)retweetMsg:(id)sender {
    if ([self.delegate respondsToSelector:@selector(retweetMessageDidTap:msgLayout:)]) {
        [self.delegate retweetMessageDidTap:self msgLayout:self.msgLayout];
    }
}

- (void)deleteMsg:(id)sender {
    if ([self.delegate respondsToSelector:@selector(deleteMessageDidTap:msgLayout:)]) {
        [self.delegate deleteMessageDidTap:self msgLayout:self.msgLayout];
    }
}


- (void)configMsgContentView {
    switch (self.msgLayout.chatMessage.msgType) {
        case LMMessageTypeText:{
            /// cell控件重用
            if ([self.msgContentView isKindOfClass:[LMMsgTextContentView class]]) {
                LMMsgTextContentView *textMsgContentView = (LMMsgTextContentView *)self.msgContentView;
                textMsgContentView.msgLayout = self.msgLayout;
            } else {
                [self.msgContentView removeFromSuperview];
                self.msgContentView = [[LMMsgTextContentView alloc] initWithLayout:self.msgLayout];
                [self.contentView addSubview:self.msgContentView];
            }
        }
            break;
        case LMMessageTypeImage:{
            /// cell控件重用
            if ([self.msgContentView isKindOfClass:[LMImageContentView class]]) {
                LMImageContentView *msgContentView = (LMImageContentView *)self.msgContentView;
                msgContentView.msgLayout = self.msgLayout;
            } else {
                [self.msgContentView removeFromSuperview];
                self.msgContentView = [[LMImageContentView alloc] initWithLayout:self.msgLayout];
                [self.contentView addSubview:self.msgContentView];
            }
        }
            break;
        case LMMessageTypeVideo:
        {
            /// cell控件重用
            if ([self.msgContentView isKindOfClass:[LMMsgVideoView class]]) {
                LMMsgVideoView *msgContentView = (LMMsgVideoView *)self.msgContentView;
                msgContentView.msgLayout = self.msgLayout;
            } else {
                [self.msgContentView removeFromSuperview];
                self.msgContentView = [[LMMsgVideoView alloc] initWithLayout:self.msgLayout];
                [self.contentView addSubview:self.msgContentView];
            }
        }
            break;
        default:
            break;
    }
    self.msgContentView.cell = self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

@end
