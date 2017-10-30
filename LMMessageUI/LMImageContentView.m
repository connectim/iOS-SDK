//
//  LMImageContentView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/19.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMImageContentView.h"
#import "UIImageView+EncryptionWeb.h"
#import "LMMessageBaseCell.h"

@interface LMImageContentView ()

@property (nonatomic ,strong) UIImageView *imageView;

@end

@implementation LMImageContentView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout {
    if (self = [super initWithLayout:msgLayout]) {
        self.imageView = [UIImageView new];
        self.imageView.size = self.size;
        
        self.imageView.layer.mask = self.bubbleImage.layer;
        
        PhotoMessage *msgImage = (PhotoMessage *)msgLayout.chatMessage.msgContent;
        
        [self.imageView setImageWithURL:[NSURL URLWithString:msgImage.thum]  ECDHKey:msgLayout.ECDHKey];
        self.imageView.layer.mask.frame = (CGRect){{0,0},self.bubbleImage.layer.frame.size};
        [self.imageView setNeedsDisplay];
        
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
    self.size = CGSizeMake(msgLayout.msgContentWidth, msgLayout.msgContentHeight);
    self.imageView.size = self.size;
    PhotoMessage *msgImage = (PhotoMessage *)msgLayout.chatMessage.msgContent;
    [self.imageView setImageWithURL:[NSURL URLWithString:msgImage.thum]  ECDHKey:msgLayout.ECDHKey];
    self.imageView.layer.mask.frame = (CGRect){{0,0},self.bubbleImage.layer.frame.size};
    [self.imageView setNeedsDisplay];
}


- (void)tapMsgContent {
    if ([self.cell.delegate respondsToSelector:@selector(imageDidTap:msgLayout:)]) {
        [self.cell.delegate imageDidTap:self.cell msgLayout:self.msgLayout];
    }
}

@end
