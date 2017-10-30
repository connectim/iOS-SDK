//
//  LMMessageManager.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageManager.h"

@implementation LMMessageManager

+ (instancetype)sharedManager {
    static LMMessageManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LMMessageManager alloc] init];
    });
    
    return _instance;
}





@end
