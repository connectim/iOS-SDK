//
//  LMSlideMeun.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/16.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMSlideMeun.h"

#define MEUN_WIDTH ([UIScreen mainScreen].bounds.size.width / 2)
#define EXTRAAREA 50

@interface LMSlideMeun ()
{
    UIWindow *keyWindow;
    CGFloat diff;
    CGFloat x;
    
    
    UIView *helpView1;
    UIView *helpView2;
    int animationCount;
}

@property (nonatomic ,strong) CADisplayLink *displayLink;

@end

@implementation LMSlideMeun

- (void)showMeun {
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = self.bounds;
    } completion:^(BOOL finished) {
        
    }];

    [self beforAnimation];
    [UIView animateWithDuration:0.7 delay:0.0f usingSpringWithDamping:0.5f initialSpringVelocity:0.9f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
//        helpView1.center = CGPointMake(keyWindow.center.x, helpView1.frame.size.height/2);
        helpView1.center = keyWindow.center;
    } completion:^(BOOL finished) {
        [self endAnimation];
    }];
    [self beforAnimation];
    [UIView animateWithDuration:0.7 delay:0.0f usingSpringWithDamping:0.8f initialSpringVelocity:2.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        helpView2.center = keyWindow.center;
    } completion:^(BOOL finished) {
        [self endAnimation];
    }];
    
}

- (void)hidenMeun {
    [UIView animateWithDuration:0.25 animations:^{
        CGRect rect = self.frame;
        rect.origin.x = - (MEUN_WIDTH + EXTRAAREA);
        self.frame= rect;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


- (void)beforAnimation {
    animationCount ++;
    NSLog(@"beforAnimation");
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(animationAciont)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)endAnimation {
    NSLog(@"endAnimation");
    animationCount --;
    if (animationCount == 0) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)animationAciont {
    
    
    ///当你给一个 CALayer 添加动画的时候，动画其实并没有改变这个 layer 的实际属性。取而代之的，系统会创建一个原始 layer 的拷贝。在文档中，苹果称这个原始 layer 为 Model Layer ，而这个复制的 layer 则被称为 Presentation Layer 。 Presentation Layer 的属性会随着动画的进度实时改变，而 Model Layer 中对应的属性则并不会改变。所以如果你想要获取动画中每个时刻的状态
    
    CALayer *sideHelperPresentationLayer   =  (CALayer *)[helpView1.layer presentationLayer];
    CALayer *centerHelperPresentationLayer =  (CALayer *)[helpView2.layer presentationLayer];
    
    CGRect centerRect = [[centerHelperPresentationLayer valueForKeyPath:@"frame"]CGRectValue];
    CGRect sideRect = [[sideHelperPresentationLayer valueForKeyPath:@"frame"]CGRectValue];
    
    diff = sideRect.origin.x - centerRect.origin.x;
    
    NSLog(@"diff %f",diff);
    [self setNeedsDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
        self.frame = CGRectMake(- (MEUN_WIDTH + EXTRAAREA), 0, MEUN_WIDTH + EXTRAAREA, keyWindow.bounds.size.height);
        self.backgroundColor = [UIColor clearColor];
        [keyWindow addSubview:self];
        diff = EXTRAAREA;
        
        helpView1 = [[UIView alloc] initWithFrame:CGRectMake(-40, 0, 40, 40)];
        helpView1.backgroundColor = [UIColor redColor];
        [self addSubview:helpView1];
        
        helpView2 = [[UIView alloc] initWithFrame:CGRectMake(-40, keyWindow.bounds.size.height, 40, 40)];
        helpView2.backgroundColor = [UIColor greenColor];
        [self addSubview:helpView2];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    [path addLineToPoint:CGPointMake(MEUN_WIDTH, 0)];
    [path addQuadCurveToPoint:CGPointMake(MEUN_WIDTH, keyWindow.bounds.size.height) controlPoint:CGPointMake(MEUN_WIDTH + diff, keyWindow.bounds.size.height / 2)];
    [path addLineToPoint:CGPointMake(0, keyWindow.bounds.size.height)];
    [path closePath];
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, path.CGPath);
    [[UIColor colorWithRed:0 green:0.8 blue:1 alpha:1] set];
    CGContextFillPath(context);
}

@end
