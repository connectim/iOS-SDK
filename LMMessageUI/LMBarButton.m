//
//  LMBarButton.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMBarButton.h"

@interface LMBarButton ()

@property (nonatomic ,strong) UIImageView *imageView;

@property (nonatomic ,assign) LMBarButtonType type;
@property (nonatomic ,assign) LMBarButtonStatus status;

@end

@implementation LMBarButton

- (instancetype)initWithNormalIcon:(NSString *)normalIcon type:(LMBarButtonType)type frame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _type = type;
        _status = LMBarButtonStatusNormal;
        self.imageView = [[UIImageView alloc] init];
//        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.frame = self.bounds;
        _imageView.image = [UIImage imageNamed:normalIcon];
        _imageView.highlightedImage = [UIImage imageNamed:@"msg_inputbar_keyboard"];
        [self addSubview:_imageView];
    }
    
    return self;
}

- (void)toNomarlStatus {
    [_imageView setHighlighted:NO];
    _status = LMBarButtonStatusNormal;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_status == LMBarButtonStatusNormal) {
        _status = LMBarButtonStatusKeyboard;
        [_imageView setHighlighted:YES];
    } else {
        _status = LMBarButtonStatusNormal;
        [_imageView setHighlighted:NO];
    }
    if ([self.delegate respondsToSelector:@selector(barButtonTapWithStatus:type:)]) {
        [self.delegate barButtonTapWithStatus:_status type:_type];
    }
}

@end
