//
//  LMEncryptKit.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMEncryptGcmData : NSObject

@property (nonatomic ,strong) NSData *aad;
@property (nonatomic ,strong) NSData *iv;
@property (nonatomic ,strong) NSData *tag;
@property (nonatomic ,strong) NSData *ciphertext;

@end

@interface LMEncryptKit : NSObject

+ (NSString *)creatConnectIMPrivkey;
+ (NSString *)connectIMPubkeyByPrikey:(NSString *)prikey;

/// 签名
+ (NSString *)signData:(NSString *)signData privkey:(NSString *)privkey;

/// 验证签名
+ (BOOL)verfiySign:(NSString *)sign signedData:(NSString *)signedData pubkey:(NSString *)pubkey;

/// 加密数据
+ (LMEncryptGcmData *)encodeAES_GCMWithECDHKey:(NSData *)ECDHKey data:(NSData *)data aad:(NSData *)aad;

/// 解密数据
+ (NSData *)decodeAES_GCMDataWithECDHKey:(NSData *)ECDHKey data:(NSData *)data aad:(NSData *)aad iv:(NSData *)iv tag:(NSData *)tag;

/// 生成协同密钥
+ (NSData *)getECDHkeyWithPrivkey:(NSString *)privkey publicKey:(NSString *)pubkey;
/// 扩展协同密钥
+ (NSData *)getAes256KeyByECDHKeyAndSalt:(NSData *)ecdhKey salt:(NSData *)salt;

+ (NSData *)createRandom512bits;

@end
