//
//  LMMsgCardContentView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/20.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMsgCardContentView.h"

@interface LMMsgCardContentView ()

@property (nonatomic ,strong) UIImageView *avatarImageView;
@property (nonatomic ,strong) YYLabel *nameLabel;
@property (nonatomic ,strong) YYLabel *leftStatusLabel;

@end

@implementation LMMsgCardContentView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout {
    if (self = [super initWithLayout:msgLayout]) {
        self.avatarImageView = [UIImageView new];
        [self addSubview:self.avatarImageView];
        
        self.nameLabel = [YYLabel new];
        [self addSubview:self.nameLabel];
        
        self.leftStatusLabel = [YYLabel new];
        [self addSubview:self.leftStatusLabel];
    }
    return self;
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    [super setMsgLayout:msgLayout];
}


@end
