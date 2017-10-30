//
//  LMMessageInputBar.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageInputBar.h"
#import <YYKit/YYKit.h>
#import "LMBarButton.h"
#import "LMMessagePanel.h"
#import "LMMessageConstant.h"

@interface LMMessageInputBar ()<YYTextViewDelegate,LMBarButtonDelegate,YYTextKeyboardObserver>

@property (nonatomic ,strong) LMBarButton *panelButton;
@property (nonatomic ,strong) LMBarButton *emojiButton;
@property (nonatomic ,strong) LMBarButton *voiceButton;
@property (nonatomic ,strong) YYTextView *textView;
@property (nonatomic ,strong) LMMessagePanel *panel;

@end

@implementation LMMessageInputBar

- (void)dealloc {
    [[YYTextKeyboardManager defaultManager] removeObserver:self];
}

#pragma mark @protocol YYTextKeyboardObserver
- (void)keyboardChangedWithTransition:(YYTextKeyboardTransition)transition {
    CGRect toFrame = [[YYTextKeyboardManager defaultManager] convertRect:transition.toFrame toView:self.superview];
    if ([self.delegate respondsToSelector:@selector(inputBarTopChange:animationDuration:)]) {
        [self.delegate inputBarTopChange:kScreenHeight - CGRectGetHeight(toFrame) - MSGInPutbarHeight animationDuration:transition.animationDuration];
    }
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        [[YYTextKeyboardManager defaultManager] addObserver:self];
        
        self.size = CGSizeMake(kScreenWidth,MSGInPutbarHeight);
        
        CALayer *line = [[CALayer alloc] init];
        line.height = 0.7;
        line.width = kScreenWidth;
        line.backgroundColor = [UIColor lightGrayColor].CGColor;
        [self.layer addSublayer:line];
        
        
        CGFloat margin = 7;
        self.panelButton = [[LMBarButton alloc] initWithNormalIcon:@"msg_inputbar_panel" type:LMBarButtonTypePanel frame:CGRectMake(margin, margin, self.height - 2 * margin, self.height - 2 * margin)];
        self.panelButton.delegate = self;
        [self addSubview:self.panelButton];

        self.textView = [YYTextView new];
        _textView.size = CGSizeMake(self.width - 5 * margin - self.panelButton.width * 3, self.panelButton.height);
        _textView.left = self.panelButton.right + margin;
        _textView.top = margin;
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.alwaysBounceVertical = YES;
        _textView.allowsCopyAttributedString = NO;
        _textView.font = [UIFont systemFontOfSize:18];
        _textView.delegate = self;
        _textView.inputAccessoryView = [UIView new];
        _textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _textView.layer.borderWidth = 0.5;
        _textView.layer.cornerRadius = 5;
        _textView.backgroundColor = [UIColor whiteColor];
        _textView.returnKeyType = UIReturnKeySend;
        [self addSubview:_textView];
        
        self.emojiButton = [[LMBarButton alloc] initWithNormalIcon:@"msg_inputbar_emoji" type:LMBarButtonTypeEmoji frame:CGRectMake(self.textView.right + margin, margin, self.panelButton.width, self.panelButton.height)];
        self.emojiButton.delegate = self;
        [self addSubview:self.emojiButton];
        
        self.voiceButton = [[LMBarButton alloc] initWithNormalIcon:@"msg_inputbar_record" type:LMBarButtonTypeVoice frame:CGRectMake(self.emojiButton.right + margin, margin, self.panelButton.width, self.panelButton.height)];
        self.voiceButton.delegate = self;
        [self addSubview:self.voiceButton];
        
        CALayer *lineB = [[CALayer alloc] init];
        lineB.height = 0.7;
        lineB.width = kScreenWidth;
        lineB.bottom = self.height;
        lineB.backgroundColor = [UIColor lightGrayColor].CGColor;
        [self.layer addSublayer:lineB];
        

//        self.panel.top = lineB.bottom;
//        [self addSubview:self.panel];
        
        self.backgroundColor = [UIColor colorWithHexString:@"e6e6e6"];
    }
    
    return self;
}


- (LMMessagePanel *)panel {
    if (!_panel) {
        _panel = [[LMMessagePanel alloc] init];
    }
    return _panel;
}

/// LMBarButtonDelegate
- (void)barButtonTapWithStatus:(LMBarButtonStatus)status type:(LMBarButtonType)type {
    switch (type) {
        case LMBarButtonTypeEmoji:
        {
            if (status == LMBarButtonStatusKeyboard) {/// 显示表情面板
                [self.textView resignFirstResponder];
            } else {
                [self.textView becomeFirstResponder];
            }
            [self.panelButton toNomarlStatus];
        }
            break;
            
        case LMBarButtonTypeVoice:
        {
            
        }
            break;
            
        case LMBarButtonTypePanel:
        {
            if (status == LMBarButtonStatusKeyboard) { /// 显示扩展面板
                [self.textView resignFirstResponder];
            } else {
                [self.textView becomeFirstResponder];
            }
            [self.emojiButton toNomarlStatus];
        }
            break;
            
        default:
            break;
    }
}

- (BOOL)textViewShouldBeginEditing:(YYTextView *)textView {
    [self.emojiButton toNomarlStatus];
    [self.panelButton toNomarlStatus];
    return YES;
}

- (BOOL)textView:(YYTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]){ //判断输入的字是否是回车，即按下return
        if ([self.delegate respondsToSelector:@selector(inputBarSendText:)]) {
            [self.delegate inputBarSendText:textView.text];
        }
        textView.text = @"";
        return NO; //这里返回NO，就代表return键值失效，即页面上按下return，不会出现换行，如果为yes，则输入页面会换行
    }
    return YES;
}

@end
