//
//  LMMessageTool.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageTool.h"
#import "LMEncryptKit.h"
#import "NSData+Hash.h"
#import "LMConnectIMChater.h"

@implementation LMMessageTool

+ (GcmData *)encodeData:(NSData *)data needPlainData:(BOOL)needPlainData withECDHKey:(NSData *)ECDHKey needEmptySalt:(BOOL)needEmptySalt aad:(NSData *)aad {
    if (!data || !ECDHKey) {
        return nil;
    }
    if (needPlainData) {
        data = [self createPlainData:data];
    }
    if (needEmptySalt) {
        ECDHKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ECDHKey salt:[self get64ZeroData]];
    }
    if (!aad) {
        aad = [@"ConnectEncrypted" dataUsingEncoding:NSUTF8StringEncoding];
    }
    LMEncryptGcmData *encryGcm = [LMEncryptKit encodeAES_GCMWithECDHKey:ECDHKey data:data aad:aad];
    GcmData *gcmData = [GcmData new];
    gcmData.aad = encryGcm.aad;
    gcmData.iv = encryGcm.iv;
    gcmData.tag = encryGcm.tag;
    gcmData.ciphertext = encryGcm.ciphertext;
    return gcmData;
}

+ (GcmData *)encodeData:(NSData *)data needPlainData:(BOOL)needPlainData withECDHKey:(NSData *)ECDHKey {
    return [self encodeData:data needPlainData:needPlainData withECDHKey:ECDHKey needEmptySalt:NO aad:nil];
}
+ (GcmData *)encodeData:(NSData *)data needPlainData:(BOOL)needPlainData withEmptySlatECDHKey:(NSData *)ECDHKey {
    return [self encodeData:data needPlainData:needPlainData withECDHKey:ECDHKey needEmptySalt:YES aad:nil];
}


+ (NSData *)decodeGcmData:(GcmData *)gcmData ECDHKey:(NSData *)ECDHKey needEmptySalt:(BOOL)needEmptySalt havePlainData:(BOOL)havePlainData {
    if (!gcmData || !ECDHKey) {
        return nil;
    }
    if (needEmptySalt) {
        ECDHKey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ECDHKey salt:[self get64ZeroData]];
    }
    NSData *data = [LMEncryptKit decodeAES_GCMDataWithECDHKey:ECDHKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    if (havePlainData) {
        return [self getPlainDataWithData:data];
    } else {
        return data;
    }
}

+ (NSData *)decodeGcmDataWithEmptySaltEcdhKey:(NSData *)ecdhKey
                                      GcmData:(GcmData *)gcmData havePlainData:(BOOL)havePlainData{
    return [self decodeGcmData:gcmData ECDHKey:ecdhKey needEmptySalt:YES havePlainData:havePlainData];
}

+ (NSData *)decodeGcmDataWithEcdhKey:(NSData *)ecdhKey
                             GcmData:(GcmData *)gcmData havePlainData:(BOOL)havePlainData{
    return [self decodeGcmData:gcmData ECDHKey:ecdhKey needEmptySalt:NO havePlainData:havePlainData];
}

+ (NSData *)getPlainDataWithData:(NSData *)data{
    StructData *structData = [StructData parseFromData:data error:nil];
    return structData.plainData;
}

+ (NSData *)createPlainData:(NSData *)data{
    StructData *structData = [StructData new];
    structData.plainData = data;
    structData.random = [self get16_32RandData];
    return structData.data;
}


+ (IMTransferData *)makeTransferDataWithData:(NSData *)data ECDHKey:(NSData *)ECDHKey {
    if (!data || !ECDHKey) {
        return nil;
    }
    IMTransferData *transferData = [IMTransferData new];
    transferData.cipherData = [self encodeData:data needPlainData:YES withECDHKey:ECDHKey];
    transferData.sign = [LMEncryptKit signData:[transferData.cipherData.data hash256String] privkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey];
    
    return transferData;
}

+ (IMTransferData *)makeTransferDataWithExtensionPass_Data:(NSData *)data {
    return [self makeTransferDataWithData:data ECDHKey:[LMConnectIMChater sharedManager].chatSessionManager.socketExtensionECDH];
}


+ (IMRequest *)makeRequestWithData:(NSData *)data ECDHKey:(NSData *)ECDHKey {
    GcmData *gcmData = [self encodeData:data needPlainData:YES withEmptySlatECDHKey:ECDHKey];
    IMRequest *request = [[IMRequest alloc] init];
    request.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    request.cipherData = gcmData;
    request.sign = [LMEncryptKit signData:[gcmData.data hash256String] privkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey];
    return request;
}

+ (NSData *)decodeRequest:(IMResponse *)response ECDHKey:(NSData *)ECDHKey {
    if ([LMEncryptKit verfiySign:response.sign signedData:[response.cipherData.data hash256String] pubkey:[LMConnectIMChater sharedManager].chatSessionManager.connectServerPubkey]) {
        return [self decodeGcmDataWithEcdhKey:ECDHKey GcmData:response.cipherData havePlainData:YES];
    }
    return nil;
}

+ (MessagePost *)makeMessagePostWithMsgData:(MessageData *)msgData {
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
    messagePost.msgData = msgData;
    messagePost.sign = [LMEncryptKit signData:[msgData.data hash256String] privkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey];
    
    return messagePost;
}


+ (NSData *)get64ZeroData{
    NSMutableData *mData = [NSMutableData data];
    const char zeroChar = 0x00;
    int len = 64;
    while (len > 0) {
        [mData appendBytes:&zeroChar length:sizeof(zeroChar)];
        len --;
    }
    return [NSData dataWithData:mData];
}

+ (NSData *)get16_32RandData{
    NSData *randomData = [LMEncryptKit createRandom512bits];
    int loc = arc4random() % 32;
    int len = arc4random() % 16 + 16;
    randomData = [randomData subdataWithRange:NSMakeRange(loc, len)];
    return randomData;
}

+ (NSString *)generateMessageId{
    return [NSString stringWithFormat:@"%lld%d",(int long long)([[NSDate date] timeIntervalSince1970] * 1000),(arc4random() % 999) + 101];
}


@end
