//
//  LMMsgVideoView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/10.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMsgVideoView.h"
#import "UIImageView+EncryptionWeb.h"
#import "LMMessageBaseCell.h"
#import "LMDownLoadManager.h"
#import "LMDownloadAniView.h"

@interface LMMsgVideoView ()

@property (nonatomic ,strong) UIImageView *imageView;

@property (nonatomic, strong) UIView *customMaskView;
@property (nonatomic, strong) YYLabel *videoTimeLabel;
@property (nonatomic, strong) YYLabel *videoSizeLabel;
@property (nonatomic ,strong) LMDownloadAniView *downloadView;

@end

@implementation LMMsgVideoView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout {
    if (self = [super initWithLayout:msgLayout]) {
        self.imageView = [UIImageView new];
        self.imageView.size = self.size;
        
        self.imageView.layer.mask = self.bubbleImage.layer;
        [self addSubview:self.imageView];
        
        self.downloadView = [[LMDownloadAniView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        self.downloadView.selected = msgLayout.videoDownloaded;
        self.downloadView.center = self.center;
        [self.downloadView addTarget:self action:@selector(downVideo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.downloadView];
        
        
        self.customMaskView = [UIView new];
        self.customMaskView.height = 15;
        self.customMaskView.width = self.width;
        self.customMaskView.bottom = self.height;
        self.customMaskView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
        [self.imageView addSubview:self.customMaskView];
        
        self.videoTimeLabel = [YYLabel new];
        [self.customMaskView addSubview:self.videoTimeLabel];
        self.videoSizeLabel = [YYLabel new];
        [self.customMaskView addSubview:self.videoSizeLabel];

        /// 设置数据
        [self setMsgLayout:msgLayout];
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
    self.size = CGSizeMake(msgLayout.msgContentWidth, msgLayout.msgContentHeight);
    self.imageView.size = self.size;
    VideoMessage *videoMsg = (VideoMessage *)msgLayout.chatMessage.msgContent;
    [self.imageView setImageWithURL:[NSURL URLWithString:videoMsg.cover]  ECDHKey:msgLayout.ECDHKey];
    self.imageView.layer.mask.frame = (CGRect){{0,0},self.bubbleImage.layer.frame.size};
    [self.imageView setNeedsDisplay];
    
    self.downloadView.selected = msgLayout.videoDownloaded;
    
    self.videoTimeLabel.textLayout = msgLayout.videoTimeLayout;
    self.videoTimeLabel.size = msgLayout.videoTimeLayout.textBoundingSize;
    self.videoTimeLabel.height = self.customMaskView.height;
    
    self.videoSizeLabel.textLayout = msgLayout.videoSizeLayout;
    self.videoSizeLabel.size = msgLayout.videoSizeLayout.textBoundingSize;
    self.videoSizeLabel.height = self.customMaskView.height;
    
    if (msgLayout.chatMessage.sendFromSelf) {
        self.videoTimeLabel.left =  MSGCellMargin;
        self.videoSizeLabel.right =  msgLayout.msgContentWidth - MSGCellMargin - MSGBubbleHorn;
    } else {
        self.videoTimeLabel.left =  MSGCellMargin + MSGBubbleHorn;
        self.videoSizeLabel.right =  msgLayout.msgContentWidth - MSGCellMargin;
    }
    
}

- (void)tapMsgContent {
}

- (void)downVideo {
    if (self.downloadView.isSelected) {
        if ([self.cell.delegate respondsToSelector:@selector(videoDidTap:msgLayout:)]) {
            [self.cell.delegate videoDidTap:self.cell msgLayout:self.msgLayout];
        }
    } else {
        [self.downloadView startLoading];
        VideoMessage *videoMsg = (VideoMessage *)self.msgLayout.chatMessage.msgContent;
        NSString *videoName = [NSString stringWithFormat:@"%@%@",self.msgLayout.chatMessage.msgOwer,self.msgLayout.chatMessage.msgId];
        [[LMDownLoadManager sharedManager] downloadVideoWithUrl:videoMsg.URL videoName:videoName ECDHKey:self.msgLayout.ECDHKey progress:^(NSProgress *downloadProgress) {
            NSLog(@"downloadProgress %f",downloadProgress.completedUnitCount / downloadProgress.totalUnitCount * 1.f);
        } complete:^(NSURL *videoUrl, NSError *error) {
            if (!error) {
                self.downloadView.selected = YES;
                self.msgLayout.videoDownloaded = YES;
                self.msgLayout.videoURL = videoUrl;
                [self.downloadView downLoadSuccess];
            } else {
                NSLog(@"video error %@",error);
            }
        }];
    }
}

@end
