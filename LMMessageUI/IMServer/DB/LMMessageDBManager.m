//
//  LMMessageDBManager.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/9.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageDBManager.h"
#import "LMMessageTool.h"
@implementation LMMessageDBManager

- (void)saveMessage:(LMMessage *)message {
    
}

- (void)batchSaveMessage:(NSArray<LMMessage *> *)messagees {
    
}

- (void)updateMessageStatus:(LMMessageStatus)status withMessageOwer:(NSString *)msgOwer messageId:(NSString *)messageId {
    
}

- (NSArray<LMMessage *> *)fetchMessageFromTime:(NSDate *)lastMessageTime limit:(int)limit {
    LMMessage *msg = [LMMessage new];
    msg.msgOwer = @"02edcd543967c989668e4312fb0c0a3fdcb3e5dea7e73c3fba7261fe2f491166b4";
    msg.msgId = [LMMessageTool generateMessageId];
    msg.createTime = [NSDate date];
    NotifyMessage *tip = [NotifyMessage new];
    tip.content = @"这是一段提示文字哈哈哈哈哈哈哈哈哈哈哈";
    tip.notifyType = LMMessageTipTypeNormal;
    msg.msgContent = tip;
    msg.msgType = LMMessageTypeTip;
    NSMutableArray *messageArray = [NSMutableArray array];
    [messageArray addObject:msg];
    
    
    for (int i = 0; i < 20; i ++) {
        LMMessage *msg = [LMMessage new];
        msg.msgOwer = @"02edcd543967c989668e4312fb0c0a3fdcb3e5dea7e73c3fba7261fe2f491166b4";
        msg.msgId = @"12345";
        msg.createTime = [NSDate date];
        msg.sendFromSelf = i % 2;
        if (msg.sendFromSelf) {
            msg.senderId = @"0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0";
        } else {
            msg.senderId = @"02edcd543967c989668e4312fb0c0a3fdcb3e5dea7e73c3fba7261fe2f491166b4";
        }
        msg.status = LMMessageStatusSuccess;
        if (i % 3) {
            msg.msgType = LMMessageTypeText;
            TextMessage *text = [TextMessage new];
            text.content = @"当获取到";
            msg.msgContent = text;
        } else {
            msg.msgType = LMMessageTypeImage;
            PhotoMessage *image = [PhotoMessage new];
            image.URL = @"http://192.168.40.4:18081/fs/v1/f/ad21e7c623e4ec5fd3f0be574c42c3b3be0b87ac?pub_key=0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0&token=b1f2f67fb0bb4d357c0396bc7952dccb06efa8e0243e182de7be942f6c0ffd33";
            image.thum = @"http://192.168.40.4:18081/fs/v1/f/ad21e7c623e4ec5fd3f0be574c42c3b3be0b87ac/thumb?pub_key=0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0&token=b1f2f67fb0bb4d357c0396bc7952dccb06efa8e0243e182de7be942f6c0ffd33";
            image.imageWidth = 828;
            image.imageHeight = 1472;
            msg.msgContent = image;
        }

        if (i % 10 == 0) {
            msg.msgType = LMMessageTypeVideo;
            VideoMessage *video = [VideoMessage new];
            video.URL = @"http://192.168.40.4:18081/fs/v1/f/6ae05eadccc5c9a6720ab48f951d0856e18aa9d6?pub_key=0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0&token=a6c051d3451e050bcfbc39eecd22f326ecce360790d1805b5a85d08cfb5d00ad";
            video.cover = @"http://192.168.40.4:18081/fs/v1/f/6ae05eadccc5c9a6720ab48f951d0856e18aa9d6/thumb?pub_key=0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0&token=a6c051d3451e050bcfbc39eecd22f326ecce360790d1805b5a85d08cfb5d00ad";
            video.imageWidth = 1080;
            video.imageHeight = 1920;
            video.timeLength = 3;
            video.size = 348031;
            msg.msgContent = video;
        }
        
        [messageArray addObject:msg];
    }
    
    tip.content = @"这是一段提示文字这是一段提示文字这是一段提示文字这是一段提示文字这是一段提示文字这是一段提示文字";
    [messageArray addObject:msg];
    [messageArray addObject:msg];
    
    return messageArray;
}

@end
