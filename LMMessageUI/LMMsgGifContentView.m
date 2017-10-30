//
//  LMMsgGifContentView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/21.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMsgGifContentView.h"

@interface LMMsgGifContentView ()

@property (nonatomic ,strong) YYAnimatedImageView *gifImage;

@end


@implementation LMMsgGifContentView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout {
    if (self = [super initWithLayout:msgLayout]) {
        self.gifImage = [YYAnimatedImageView new];
        [self addSubview:self.gifImage];
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
    EmotionMessage *emotion = (EmotionMessage *)msgLayout.chatMessage.msgContent;
}


@end
