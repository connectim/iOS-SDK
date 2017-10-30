//
//  LMIMMessageHandler.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/28.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@interface LMIMMessageHandler : NSObject

/// handle online message
+ (void)handldMessage:(Message *)msg;


/// handle offline message
+ (void)handldOfflineMessage:(Message *)msg;

@end
