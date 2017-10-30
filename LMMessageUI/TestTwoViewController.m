//
//  TestTwoViewController.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/17.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "TestTwoViewController.h"
#import "LMTransitionAnimation.h"
#import "LMDownloadView.h"

@interface TestTwoViewController () <UIViewControllerTransitioningDelegate,CAAnimationDelegate>
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIButton *animationBtn;

@property (nonatomic ,strong) LMDownloadView *downloadView;

@end

@implementation TestTwoViewController
- (IBAction)jumpAnimation:(id)sender {
    /// 旋转
    CABasicAnimation *oneAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    oneAnimation.fromValue = @(0);
    oneAnimation.toValue = @(M_PI_2);
    
    /// 向上跳跃
    CABasicAnimation *jumpAnimation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    jumpAnimation.fromValue = @(self.animationBtn.center.y);
    jumpAnimation.fromValue = @(self.animationBtn.center.y - 15);
    
    /// 放大
    CAKeyframeAnimation *sacleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"scale"];
    sacleAnimation.values = @[@(1.0),@(1.2)];
    sacleAnimation.keyTimes = @[@(0),@(1.0)];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 0.25;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    group.delegate = self;
    group.animations = @[oneAnimation,jumpAnimation,sacleAnimation];
    
    [self.animationBtn.layer addAnimation:group forKey:@"jumpani"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([anim isEqual:[self.animationBtn.layer animationForKey:@"jumpani"]]) {
        self.animationBtn.selected = !self.animationBtn.selected;
        /// 旋转
        CABasicAnimation *oneAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
        oneAnimation.fromValue = @(M_PI_2);
        oneAnimation.toValue = @(M_PI_2);
        
        /// 向上跳跃
        CABasicAnimation *jumpAnimation = [CABasicAnimation animationWithKeyPath:@"position.y"];
        jumpAnimation.fromValue = @(self.animationBtn.center.y - 15);
        jumpAnimation.fromValue = @(self.animationBtn.center.y);
        
        /// 放大
        CAKeyframeAnimation *sacleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"scale"];
        sacleAnimation.values = @[@(1.2),@(1.0)];
        sacleAnimation.keyTimes = @[@(0),@(1.0)];
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.duration = 0.15;
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;
        group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        group.delegate = self;
        group.animations = @[oneAnimation,jumpAnimation,sacleAnimation];
        
        [self.animationBtn.layer addAnimation:group forKey:@"downani"];
    } else if ([anim isEqual:[self.animationBtn.layer animationForKey:@"downani"]]) {
        [self.animationBtn.layer removeAllAnimations];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.transitioningDelegate = self;
    
    [self.animationBtn setImage:[UIImage imageNamed:@"msg_sendfailed"] forState:UIControlStateSelected];
    
    
    self.downloadView = [[LMDownloadView alloc] initWithFrame:CGRectMake(self.view.center.x,self.view.center.y, 100, 100)];
    
    [self.view addSubview:self.downloadView];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.container.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:self.container.bounds.size];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    
    self.container.layer.mask = shapeLayer;
    
    
    CAGradientLayer *gradLayer = [CAGradientLayer layer];
    gradLayer.frame = self.container.bounds;
    gradLayer.colors = @[(__bridge id)[UIColor redColor].CGColor,(__bridge id)[UIColor yellowColor].CGColor,(__bridge id)[UIColor greenColor].CGColor,(__bridge id)[UIColor blueColor].CGColor,(__bridge id)[UIColor purpleColor].CGColor];
    gradLayer.locations = @[@(0.2),@(0.4),@(0.6),@(0.8),@(1)];
    gradLayer.startPoint = CGPointMake(0, 0);
    gradLayer.startPoint = CGPointMake(1, 1);
    
    [self.container.layer addSublayer:gradLayer];
    
    
    [self showAnimation];
    
}

- (void)showAnimation {
    /// 位置变化
    CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    keyAnimation.removedOnCompletion = NO;
    keyAnimation.fillMode = kCAFillModeForwards;
    keyAnimation.repeatCount = MAXFLOAT;
    keyAnimation.calculationMode = kCAAnimationPaced;
    keyAnimation.duration = 5;

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.container.center.x - 5, self.container.center.y -3, 11, 7) cornerRadius:4];
    keyAnimation.path = path.CGPath;
    
    [self.container.layer addAnimation:keyAnimation forKey:@"ani_position"];
    
    /// 纵向变化
    CAKeyframeAnimation *xAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    xAnimation.removedOnCompletion = NO;
    xAnimation.fillMode = kCAFillModeForwards;
    xAnimation.repeatCount = MAXFLOAT;
    xAnimation.calculationMode = kCAAnimationPaced;
    xAnimation.duration = 6;
    xAnimation.values = @[@(1.0),@(1.1),@(1.0)];
    xAnimation.keyTimes = @[@(0),@(0.5),@(1.0)];
    
    [self.container.layer addAnimation:xAnimation forKey:@"ani_x"];
    
    /// 横向变化
    CAKeyframeAnimation *yAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    yAnimation.removedOnCompletion = NO;
    yAnimation.fillMode = kCAFillModeForwards;
    yAnimation.repeatCount = MAXFLOAT;
    yAnimation.calculationMode = kCAAnimationPaced;
    yAnimation.duration = 8;
    yAnimation.values = @[@(1.0),@(1.1),@(1.0),@(0.9),@(1.0)];
    yAnimation.keyTimes = @[@(0),@(0.3),@(5.0),@(0.8),@(1.0)];
    
    [self.container.layer addAnimation:yAnimation forKey:@"ani_y"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
