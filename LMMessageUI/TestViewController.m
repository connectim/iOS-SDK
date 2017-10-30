//
//  TestViewController.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/16.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "TestViewController.h"
#import <YYKit/YYKit.h>
#import "LMSlideMeun.h"
#import "LMTransitionAnimation.h"

@interface TestViewController ()<UIViewControllerTransitioningDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *layerView1;
@property (weak, nonatomic) IBOutlet UIImageView *layerView2;

@property (nonatomic ,strong) LMSlideMeun *meun;
@property (nonatomic ,strong) LMTransitionAnimation *lm_animation;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lm_animation = [LMTransitionAnimation new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.delegate=self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *two = segue.destinationViewController;
    two.transitioningDelegate = self;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationPush) {
        return self.lm_animation;
    }
    return nil;
}

- (IBAction)clickBtn:(UIButton *)sender {
    if (!_meun) {
        _meun = [[LMSlideMeun alloc] init];
    }
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_meun showMeun];
    } else {
        [_meun hidenMeun];
        _meun = nil;
    }
}

@end
