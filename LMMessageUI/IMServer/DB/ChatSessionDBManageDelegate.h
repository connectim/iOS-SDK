//
//  ChatSessionDBManageDelegate.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/10.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessage.h"

@protocol ChatSessionDBManageDelegate <NSObject>


- (NSString *)unreadCount;

- (void)messageDidReceive:(LMMessage *)message;

@end
