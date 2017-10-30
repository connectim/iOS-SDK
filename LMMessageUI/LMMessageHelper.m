//
//  LMMessageHelper.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageHelper.h"
#import "LMMessageTipCell.h"
#import "LMMessageCell.h"

@implementation LMMessageHelper

+ (NSString *)cellIdentifierWithMsgType:(LMMessageType)msgType {
    switch (msgType) {
        case LMMessageTypeTip:
            return [NSString stringWithFormat:@"LMMessageTypeTipID"];
            break;
        case LMMessageTypeTime:
            return [NSString stringWithFormat:@"LMMessageTypeTipID"];
            break;
        default:
            return [NSString stringWithFormat:@"LMMessageCellID"];
            break;
    }
    
    return @"ID";
}

+ (void)regisgerMsgCellWithTableView:(UITableView *)tableView {
    [tableView registerClass:[LMMessageTipCell class] forCellReuseIdentifier:@"LMMessageTypeTipID"];
    [tableView registerClass:[LMMessageCell class] forCellReuseIdentifier:@"LMMessageCellID"];
}

@end
