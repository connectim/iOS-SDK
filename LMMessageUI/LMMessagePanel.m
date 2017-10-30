//
//  LMMessagePanel.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/25.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessagePanel.h"
#import <YYKit/YYKit.h>
#import "LMMessageConstant.h"

@implementation LMMessagePanel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.size = CGSizeMake(kScreenWidth, MSGInExtensionHeight);
        self.backgroundColor = [UIColor colorWithHexString:@"e6e6e6"];
    }
    return self;
}

@end
