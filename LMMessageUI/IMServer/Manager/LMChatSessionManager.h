//
//  LMChatSessionManager.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/26.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.pbobjc.h"

@interface LMChatSessionManager : NSObject

+ (LMChatSessionManager *)shareManager;


- (void)configWithConnectUid:(NSString *)uid connectPubkey:(NSString *)pubkey connectPrikey:(NSString *)prikey connectServerPubkey:(NSString *)serverPubkey;

/// frist connect to server ,random salt / random privkey random pubkey
@property(nonatomic, strong) NSData *sendSalt;
@property(nonatomic, copy) NSString *randomPrivkey;
@property(nonatomic, copy) NSString *randomPublickey;

/// random login connect user chatcookie
@property (nonatomic ,strong) ChatCacheCookie *loginUserChatSession;

/// connect user prikey and pubkey ,used to encrypt and sign
@property (nonatomic ,copy) NSString *connectPrikey;
@property (nonatomic ,copy) NSString *connectPubkey;
/// connect user connectid, unipue
@property (nonatomic ,copy) NSString *connectUid;

/// connect server pubkey
@property (nonatomic ,copy) NSString *connectServerPubkey;

/// connect user / server random extension ECDHKey
@property (nonatomic ,strong) NSData *socketExtensionECDH;

/// ConnectUserPrikey 和 服务器公钥暂时固定的key
@property (nonatomic ,strong) NSData *userServerECDH;

/// connect chat session identifier
@property (nonatomic ,copy) NSString *currentChatSession;
/// eg:....
@property (nonatomic ,strong) id currentChatObject;

/// update login user chatcookie
- (void)updateLoginUserChatSession:(ChatCacheCookie *)chatSession;
/// quit user
- (void)quitChatSession;

/// add or update friend chatcookie
- (void)addOrUpdateChatUserSession:(ChatCookieData *)userChatSession uid:(NSString *)uid;
- (void)removeChatUserSessionWithUid:(NSString *)uid;
/// get friend chatcookie
- (ChatCookieData *)chatUserSessionWithUid:(NSString *)uid;

@end
