//
//  LMBarButton.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMessageConstant.h"

@protocol LMBarButtonDelegate <NSObject>

- (void)barButtonTapWithStatus:(LMBarButtonStatus)status type:(LMBarButtonType)type;

@end

@interface LMBarButton : UIControl

- (instancetype)initWithNormalIcon:(NSString *)normalIcon type:(LMBarButtonType)type frame:(CGRect)frame;
- (void)toNomarlStatus;
@property (nonatomic ,weak) id <LMBarButtonDelegate> delegate;

@end
