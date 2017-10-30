//
//  LMMsgTextContentView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/19.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMsgTextContentView.h"
#import "LMMessageBaseCell.h"

@interface LMMsgTextContentView ()

@property (nonatomic ,strong) YYLabel *textContent;

@end

@implementation LMMsgTextContentView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout {
    if (self = [super initWithLayout:msgLayout]) {
        YYLabel *textContent = [YYLabel new];
        [self.bubbleImage addSubview:textContent];
        self.textContent = textContent;

        /// 设置数据
        [self setMsgLayout:msgLayout];
        __weak __typeof(&*self)weakSelf = self;
        self.textContent.highlightTapAction = ^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
            if (range.location >= text.length) return;
            YYTextHighlight *highlight = [text attribute:YYTextHighlightAttributeName atIndex:range.location];
            NSDictionary *info = highlight.userInfo;
            if (info.count == 0) return;
            if ([weakSelf.cell.delegate respondsToSelector:@selector(highlightTextDidTap:msgLayout:userInfo:)]) {
                [weakSelf.cell.delegate highlightTextDidTap:weakSelf.cell msgLayout:weakSelf.msgLayout userInfo:info];
            }
        };
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
    self.textContent.size = msgLayout.textMsgLayout.textBoundingSize;
    self.textContent.textLayout = msgLayout.textMsgLayout;
    if (self.textContent.size.height + MSGCellMargin * 2 < MSGAvatarHeight) {
        self.textContent.top = (msgLayout.msgContentHeight - self.textContent.size.height) / 2;
    } else {
        self.textContent.top = MSGCellMargin;
    }
    if (msgLayout.chatMessage.sendFromSelf) {
        self.textContent.right = msgLayout.msgContentWidth - MSGBubbleHorn - MSGCellMargin;
    } else {
        self.textContent.left = MSGBubbleHorn + MSGCellMargin;
    }
}

@end
