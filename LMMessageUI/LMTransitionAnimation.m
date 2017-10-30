//
//  LMTransitionAnimation.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/17.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMTransitionAnimation.h"

@implementation LMTransitionAnimation


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] addSubview:toViewController.view];
    
    
    fromViewController.view.layer.doubleSided = NO;
    toViewController.view.layer.doubleSided = NO;
    
    CATransform3D toTranform3d = CATransform3DIdentity;
    toTranform3d.m34 = -1 / 500;
    toTranform3d = CATransform3DMakeRotation(M_PI_2, 0, 1, 0);
    fromViewController.view.layer.transform = toTranform3d;
    
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        CATransform3D tranform3d = CATransform3DIdentity;
        tranform3d.m34 = -1 / 500;
        tranform3d = CATransform3DMakeRotation(-M_PI_2, 0, 1, 0);
        fromViewController.view.layer.transform = tranform3d;
        toViewController.view.layer.transform = tranform3d;
    } completion:^(BOOL finished) {
        fromViewController.view.transform = CGAffineTransformIdentity;
        toViewController.view.transform = CGAffineTransformIdentity;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
