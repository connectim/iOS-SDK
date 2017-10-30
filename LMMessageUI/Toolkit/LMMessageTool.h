//
//  LMMessageTool.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.pbobjc.h"

@interface LMMessageTool : NSObject

+ (GcmData *)encodeData:(NSData *)data
          needPlainData:(BOOL)needPlainData
            withECDHKey:(NSData *)ECDHKey
          needEmptySalt:(BOOL)needEmptySalt
                    aad:(NSData *)aad;

+ (GcmData *)encodeData:(NSData *)data
          needPlainData:(BOOL)needPlainData
            withECDHKey:(NSData *)ECDHKey;

+ (GcmData *)encodeData:(NSData *)data
          needPlainData:(BOOL)needPlainData
   withEmptySlatECDHKey:(NSData *)ECDHKey;


+ (NSData *)decodeGcmData:(GcmData *)gcmData
                  ECDHKey:(NSData *)ECDHKey
            needEmptySalt:(BOOL)needEmptySalt
            havePlainData:(BOOL)havePlainData;

+ (NSData *)decodeGcmDataWithEmptySaltEcdhKey:(NSData *)ecdhKey
                                      GcmData:(GcmData *)gcmData
                                havePlainData:(BOOL)havePlainData;

+ (NSData *)decodeGcmDataWithEcdhKey:(NSData *)ecdhKey
                             GcmData:(GcmData *)gcmData
                       havePlainData:(BOOL)havePlainData;



+ (IMTransferData *)makeTransferDataWithData:(NSData *)data ECDHKey:(NSData *)ECDHKey;
+ (IMTransferData *)makeTransferDataWithExtensionPass_Data:(NSData *)data;

+ (MessagePost *)makeMessagePostWithMsgData:(MessageData *)msgData;

+ (IMRequest *)makeRequestWithData:(NSData *)data ECDHKey:(NSData *)ECDHKey;
+ (NSData *)decodeRequest:(IMResponse *)response ECDHKey:(NSData *)ECDHKey;

+ (NSString *)generateMessageId;
+ (NSData *)get64ZeroData;
+ (NSData *)get16_32RandData;

@end
