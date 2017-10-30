//
//  LMDownloadView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/17.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMDownloadView.h"
#import <YYKit/YYKit.h>

#define process_height 30

@interface LMDownloadView ()<CAAnimationDelegate>

@property (nonatomic ,assign) CGRect originFrame;

@property (nonatomic ,strong) CAShapeLayer *progressLayer;

@property (nonatomic ,strong) CADisplayLink *progressLink;
@property (nonatomic ,assign) CGFloat progress;

@end

@implementation LMDownloadView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.originFrame = frame;
        self.backgroundColor = [UIColor colorWithHexString:@"87CEFA"];
        self.layer.cornerRadius = frame.size.height / 2;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect torect = CGRectMake(self.center.x - 100, self.center.y - process_height / 2, 100 * 2, process_height);
        self.frame = torect;
        self.layer.cornerRadius = process_height / 2.f;
    } completion:^(BOOL finished) {
        if (finished) {
            /// 开启下载动画
            [self startDownloadProgress];
        }
    }];
    
}

- (void)setProgress:(CGFloat)progress animation:(BOOL)animation {
    self.progressLayer.strokeEnd = progress;
    if (progress >= 1) {
        /// 移除进度条
        [self.progressLayer removeAllAnimations];
        [self.progressLayer removeFromSuperlayer];
        self.progressLayer = nil;
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.frame = self.originFrame;
            self.layer.cornerRadius = self.originFrame.size.height / 2.f;
        } completion:^(BOOL finished) {
            if (finished) {
                [self successDownload];
            }
        }];
    }
}

- (void)successDownload {
    CAShapeLayer *successLayer = [CAShapeLayer layer];
    successLayer.frame = self.bounds;
    successLayer.strokeColor = [UIColor whiteColor].CGColor;
    successLayer.fillColor = [UIColor clearColor].CGColor;
    successLayer.lineWidth = 6;
    successLayer.lineCap = kCALineCapRound;
    successLayer.lineJoin = kCALineJoinRound;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(self.frame.size.width / 2 - 10,self.frame.size.height / 2)];
    [path addLineToPoint:CGPointMake(self.frame.size.width / 2,self.frame.size.height / 2 + 10)];
    [path addLineToPoint:CGPointMake(self.frame.size.width / 2 + 15,self.frame.size.height / 2 - 20)];
    successLayer.path = path.CGPath;
    
    successLayer.strokeStart = 0;
    successLayer.strokeEnd = 1;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = 0.25;
    animation.fromValue = @(0);
    animation.toValue = @(1.f);
    
    [successLayer addAnimation:animation forKey:@"success_ani"];
    
    [self.layer addSublayer:successLayer];
}


- (void)startDownloadProgress {
    
    if (!self.progressLayer) {
        CAShapeLayer *progressLayer = [CAShapeLayer layer];
        self.progressLayer = progressLayer;
        progressLayer.frame = self.bounds;
        progressLayer.strokeColor = [UIColor whiteColor].CGColor;
        progressLayer.lineWidth = process_height - 5;
        progressLayer.lineCap = kCALineCapRound;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(process_height / 2, process_height / 2)];
        [path addLineToPoint:CGPointMake(self.frame.size.width - process_height / 2, process_height / 2)];
        progressLayer.path = path.CGPath;
        
        progressLayer.strokeStart = 0;
        progressLayer.strokeEnd = 0;
        
        [self.layer addSublayer:progressLayer];
    }
    
    self.progressLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(progressChange)];
    [self.progressLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.progressLink.paused = NO;
}

- (void)progressChange {
    self.progress += 0.01;
    [self setProgress:self.progress animation:NO];
    if (self.progress >= 1) {
        [self.progressLink invalidate];
        self.progressLink = nil;
    }
}


@end
