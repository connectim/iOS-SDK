//
//  LMMessageInputBar.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMessageConstant.h"

@protocol LMMessageInputBarDelegate <NSObject>

@optional
/// 文本
- (void)inputBarSendText:(NSString *)text;

/// 扩展面板
- (void)inputChooseMuenType:(int)meunType;

/// 表情GIF
- (void)inputChooseGifEmoji:(NSString *)gifEmoji;

/// 表情GIF
- (void)inputBarSendAudio:(NSURL *)audioUrl;


/// 输入框顶部位置
- (void)inputBarTopChange:(CGFloat)top animationDuration:(CGFloat)animationDuration;

@end

@interface LMMessageInputBar : UIView

@property (nonatomic ,weak) id <LMMessageInputBarDelegate> delegate;

@property (nonatomic ,assign) LMBarButtonStatus status;
@property (nonatomic ,assign) LMBarButtonType type;

@end
