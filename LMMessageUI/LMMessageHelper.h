//
//  LMMessageHelper.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LMMessageConstant.h"

@interface LMMessageHelper : NSObject

+ (NSString *)cellIdentifierWithMsgType:(LMMessageType)msgType;

+ (void)regisgerMsgCellWithTableView:(UITableView *)tableView;

@end
