//
//  LMDownloadAniView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/11.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMDownloadAniView.h"

#define _fromValue      @(0)
#define _endValue       @(0.8)
#define _maxValue       @(1)
#define _duration1      (1.0)

#define kAnimationDrawCircle    @"kAnimationDrawCircle"

@interface LMDownloadAniView ()<CAAnimationDelegate>
@property(nonatomic, strong) CAShapeLayer *progressLayer;
@end

@implementation LMDownloadAniView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.strokeColor = [UIColor whiteColor].CGColor;
        _progressLayer.lineWidth = 2;
        _progressLayer.frame = self.bounds;
        _progressLayer.lineJoin = kCALineJoinRound;
        _progressLayer.lineCap = kCALineCapRound;
        
        self.progressLayer.anchorPoint = CGPointMake(0, 0);
        
        UIBezierPath *roundPath = [UIBezierPath bezierPath];
        CGRect rectSelf = self.bounds;
        [roundPath addArcWithCenter:CGPointMake(0, 0) radius:CGRectGetHeight(rectSelf) / 2 startAngle:-0.5 * M_PI endAngle:2 * M_PI clockwise:YES];
        
        CGFloat w = rectSelf.size.width * 0.3;
        CGFloat radus = 5;
        [roundPath moveToPoint:CGPointMake(-radus,w - radus)];
        [roundPath addLineToPoint:CGPointMake(0,w)];
        [roundPath addLineToPoint:CGPointMake(0,-w)];
        [roundPath addLineToPoint:CGPointMake(0,w)];
        [roundPath addLineToPoint:CGPointMake(radus,w - radus)];
        
        _progressLayer.path = roundPath.CGPath;
        _progressLayer.position = CGPointMake(rectSelf.size.width / 2, rectSelf.size.height / 2);

        [self.layer addSublayer:_progressLayer];

        self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];        
        self.layer.cornerRadius = frame.size.width / 2;
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self setStatusWithSuccess:selected];
}

- (void)setStatusWithSuccess:(BOOL)success {
    [_progressLayer removeAllAnimations];
    _progressLayer.path = nil;
    if (success) {
        UIBezierPath *roundPath = [UIBezierPath bezierPath];
        CGRect rectSelf = self.bounds;
        [roundPath addArcWithCenter:CGPointMake(0, 0) radius:CGRectGetHeight(rectSelf) / 2 startAngle:-0.5 * M_PI endAngle:2 * M_PI clockwise:YES];
        
        CGFloat w = rectSelf.size.width * 0.4;
        [roundPath moveToPoint:CGPointMake(-tan(M_PI_2 / 3) * w / 2,-w / 2)];
        [roundPath addLineToPoint:CGPointMake(-tan(M_PI_2 / 3) * w / 2,w / 2)];
        [roundPath addLineToPoint:CGPointMake(tan(M_PI_2 / 3 * 2) * w / 2 - tan(M_PI_2 / 3) * w / 2,0)];
        [roundPath addLineToPoint:CGPointMake(-tan(M_PI_2 / 3) * w / 2,-w / 2)];
        _progressLayer.path = roundPath.CGPath;
    } else {
        UIBezierPath *roundPath = [UIBezierPath bezierPath];
        CGRect rectSelf = self.bounds;
        [roundPath addArcWithCenter:CGPointMake(0, 0) radius:CGRectGetHeight(rectSelf) / 2 startAngle:-0.5 * M_PI endAngle:2 * M_PI clockwise:YES];
        
        CGFloat w = rectSelf.size.width * 0.3;
        CGFloat radus = 5;
        [roundPath moveToPoint:CGPointMake(-radus,w - radus)];
        [roundPath addLineToPoint:CGPointMake(0,w)];
        [roundPath addLineToPoint:CGPointMake(0,-w)];
        [roundPath addLineToPoint:CGPointMake(0,w)];
        [roundPath addLineToPoint:CGPointMake(radus,w - radus)];
        
        _progressLayer.path = roundPath.CGPath;
    }
}

- (void)startLoading {
    [_progressLayer removeAllAnimations];
    _progressLayer.path = nil;
    
    [self drawCircleAnimation:_fromValue end:_endValue duration:_duration1];
    
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotateAnimation.repeatCount = INFINITY;
    rotateAnimation.byValue = @(M_PI * 2);
    rotateAnimation.duration = 0.7;
    [_progressLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
}

- (void)downLoadSuccess {
    [_progressLayer removeAllAnimations];
    _progressLayer.path = nil;
    
    UIBezierPath *roundPath = [UIBezierPath bezierPath];
    CGRect rectSelf = self.bounds;
    [roundPath addArcWithCenter:CGPointMake(0, 0) radius:CGRectGetHeight(rectSelf) / 2 startAngle:-0.5 * M_PI endAngle:2 * M_PI clockwise:YES];

    CGFloat w = rectSelf.size.width * 0.4;
    [roundPath moveToPoint:CGPointMake(-tan(M_PI_2 / 3) * w / 2,-w / 2)];
    [roundPath addLineToPoint:CGPointMake(-tan(M_PI_2 / 3) * w / 2,w / 2)];
    [roundPath addLineToPoint:CGPointMake(tan(M_PI_2 / 3 * 2) * w / 2 - tan(M_PI_2 / 3) * w / 2,0)];
    [roundPath addLineToPoint:CGPointMake(-tan(M_PI_2 / 3) * w / 2,-w / 2)];
    
    _progressLayer.path = roundPath.CGPath;
    CABasicAnimation *headStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [headStartAnimation setValue:kAnimationDrawCircle forKey:@"id"];
    headStartAnimation.fromValue = _fromValue;
    headStartAnimation.toValue = _maxValue;
    headStartAnimation.duration = _duration1;
    headStartAnimation.fillMode = kCAFillModeForwards;
    headStartAnimation.removedOnCompletion = NO;
    headStartAnimation.delegate = self;
    headStartAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_progressLayer addAnimation:headStartAnimation forKey:kAnimationDrawCircle];
}

- (void)drawCircleAnimation:(NSNumber *)from end:(NSNumber *)end duration:(CGFloat)duration {
    UIBezierPath *roundPath = [UIBezierPath bezierPath];
    CGRect rectSelf = self.bounds;
    [roundPath addArcWithCenter:CGPointMake(0, 0) radius:CGRectGetHeight(rectSelf) / 2 startAngle:-0.5 * M_PI endAngle:1.5 * M_PI clockwise:YES];
    _progressLayer.path = roundPath.CGPath;
    
    CABasicAnimation *headStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [headStartAnimation setValue:kAnimationDrawCircle forKey:@"id"];
    headStartAnimation.fromValue = from;
    headStartAnimation.toValue = end;
    headStartAnimation.duration = duration;
    headStartAnimation.fillMode = kCAFillModeForwards;
    headStartAnimation.removedOnCompletion = NO;
    headStartAnimation.delegate = self;
    headStartAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_progressLayer addAnimation:headStartAnimation forKey:kAnimationDrawCircle];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSLog(@"ddd");
}

@end
