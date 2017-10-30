//
//  LMMsgBaseContentView.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/19.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMessageLayout.h"

@class LMMessageBaseCell;

@interface LMMsgBaseContentView : UIView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout;

@property (nonatomic ,weak) LMMessageBaseCell *cell;
@property (nonatomic ,strong) LMMessageLayout *msgLayout;
@property (nonatomic ,strong) UIImageView *bubbleImage;

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

- (void)tapMsgContent;

@end
