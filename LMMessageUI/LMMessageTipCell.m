//
//  LMMessageTipCell.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageTipCell.h"
#import <YYKit/YYKit.h>

@interface LMMessageTipCell ()

@end

@implementation LMMessageTipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backView = [UIView new];
        self.backView.backgroundColor = MSGBackContentColor;
        self.backView.top = MSGCellMargin;
        self.backView.layer.cornerRadius = 5;
        self.backView.layer.masksToBounds = YES;
        [self.contentView addSubview:self.backView];
        self.tipLabel = [YYLabel new];
        [self.backView addSubview:self.tipLabel];
        __weak __typeof(&*self)weakSelf = self;
        self.tipLabel.highlightTapAction = ^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
            if (range.location >= text.length) return;
            YYTextHighlight *highlight = [text attribute:YYTextHighlightAttributeName atIndex:range.location];
            NSDictionary *info = highlight.userInfo;
            if (info.count == 0) return;
            if ([weakSelf.delegate respondsToSelector:@selector(highlightTextDidTap:msgLayout:userInfo:)]) {
                [weakSelf.delegate highlightTextDidTap:weakSelf msgLayout:weakSelf.msgLayout userInfo:info];
            }
        };
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
    
    self.backView.width = msgLayout.msgContentWidth;
    self.backView.height = msgLayout.msgContentHeight;
    self.backView.centerX = kScreenWidth / 2.;
    
    self.tipLabel.size = msgLayout.tipLayout.textBoundingSize;
    self.tipLabel.textLayout = msgLayout.tipLayout;
    self.tipLabel.left = MSGCellMargin;
    self.tipLabel.top = MSGCellMargin / 2.;
}

@end
