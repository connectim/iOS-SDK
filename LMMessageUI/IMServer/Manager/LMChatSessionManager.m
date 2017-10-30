//
//  LMChatSessionManager.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/26.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMChatSessionManager.h"
#import "LMEncryptKit.h"

@interface LMChatSessionManager ()

@property (nonatomic ,strong) NSMutableDictionary *userChatSessionDict;

@end

@implementation LMChatSessionManager

+ (LMChatSessionManager *)shareManager {
    static dispatch_once_t onceToken;
    static LMChatSessionManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[LMChatSessionManager alloc] init];
    });
    return instance;
}


- (void)configWithConnectUid:(NSString *)uid connectPubkey:(NSString *)pubkey connectPrikey:(NSString *)prikey connectServerPubkey:(NSString *)serverPubkey {
    
    NSAssert(uid.length > 0, @"connect uid is nil");
    NSAssert(pubkey.length > 0, @"connect pubkey is nil");
    NSAssert(prikey.length > 0, @"connect prikey is nil");
    NSAssert(serverPubkey.length > 0, @"connect server pubkey is nil");
    
    self.connectUid = uid;
    self.connectPubkey = pubkey;
    self.connectPrikey = prikey;
    self.connectServerPubkey = serverPubkey;
}

- (ChatCacheCookie *)loginUserChatSession {
    if (!_loginUserChatSession) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_chatsession",self.connectUid]];
        _loginUserChatSession = [ChatCacheCookie parseFromData:data error:nil];
    }
    
    return _loginUserChatSession;
}

- (void)updateLoginUserChatSession:(ChatCacheCookie *)chatSession {
    /// 保存到本地
    [[NSUserDefaults standardUserDefaults] setObject:chatSession.data forKey:[NSString stringWithFormat:@"%@_chatsession",self.connectUid]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    /// 更新数据
    self.loginUserChatSession = chatSession;
}

- (void)quitChatSession {
    _currentChatSession = nil;
}


- (void)addOrUpdateChatUserSession:(ChatCookieData *)userChatSession uid:(NSString *)uid{
    if (!self.userChatSessionDict) {
        self.userChatSessionDict = [NSMutableDictionary dictionary];
    }
    /// 缓存在本地
    [self.userChatSessionDict setObject:userChatSession forKey:uid];
    /// 保存到本地
    [[NSUserDefaults standardUserDefaults] setObject:userChatSession.data forKey:uid];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeChatUserSessionWithUid:(NSString *)uid {
    [self.userChatSessionDict removeObjectForKey:uid];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:uid];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (ChatCookieData *)chatUserSessionWithUid:(NSString *)uid {
    /// 缓存在本地
    ChatCookieData *userChatSession = [self.userChatSessionDict objectForKey:uid];
    if (!userChatSession) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:uid];
        if (data.length > 0) {
            userChatSession = [ChatCookieData parseFromData:data error:nil];
            /// 缓存在内存中
            [self.userChatSessionDict setObject:userChatSession forKey:uid];
        }
    }
    return userChatSession;
}


- (NSData *)userServerECDH {
    if (!_userServerECDH) {
        _userServerECDH = [LMEncryptKit getECDHkeyWithPrivkey:self.connectPrikey publicKey:self.connectServerPubkey];
    }
    return _userServerECDH;
}

@end
