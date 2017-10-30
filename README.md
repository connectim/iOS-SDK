# IM Sdk接入和API接口文档（iOS）

## IM通讯能力库
### 准备工作
1. 配置服务器公钥（Connect server pubkey）
2. 注册一个Connect的账号，获取Connectpubkey 、ConnectPrikey 、ConnectUid


### 配置用户信息和服务器信息

- 配置服务器和账号信息
```
/// 配置服务器和账号信息
/// config server host and port
@property(nonatomic, copy) NSString *host;
@property(nonatomic, assign) int32_t *port;
```

- 配置会话Session信息
```
[[LMConnectIMChater sharedManager].chatSessionManager configWithConnectUid:@"1234560" connectPubkey:@"0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0" connectPrikey:@"L2KqiWPMJQWxCBmTTPWsHiLi6ujKgJRiizzzBatRiZ8C2Uh8ZNNT" connectServerPubkey:@"03d307e51af08983cc0c13bb11d3619758e7b0b8a374e610de3503fc4ebeedfe96"];
```

### 链接服务器
```
/// 开启服务使用的默认的server地址和端口
[[LMConnectIMChater sharedManager] startIMServer];
```


### 发送和接受消息
连接服务器成功之后，您就可以收发消息了，下面以文本消息为例，说明消息的收发。
1. 封装消息
```
LMMessage *msg = [LMMessage new];
msg.msgOwer = self.chatUser.uid;
msg.msgId = [LMMessageTool generateMessageId];
msg.senderId = self.loginUser.uid;
msg.createTime = [NSDate date];
msg.sendFromSelf = YES;
msg.msgType = LMMessageTypeText; /// 文本消息
TextMessage *text = [TextMessage new];
text.content = msgtext;
msg.msgContent = @"发送一条文本消息"; /// 消息内容
```

2. 发送消息
- 发送个人和系统消息消息
```
/// 发送个人和系统消息消息
[[LMConnectIMChater sharedManager] sendP2PMessageInfo:msg progress:^(NSString *to, NSString *msgId, CGFloat progress) {
    /// 富文本的上传进度
} complete:^(ChatMessage *chatMsg, NSError *error) {
    /// 回调
}];
```

- 发送群组消息
```
/// 发送群组消息
- (void)sendGroupChatMessageInfo:(LMMessage *)msg groupECDHKey:(NSString *)groupECDHKey progress:(void (^)(NSString *to, NSString *msgId, CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete;
```

- 发送消息已读回执
```
/// 发送群组消息
- (void)messageDidReadWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg, NSError *error))complete;
```

- 发送在线消息ACK回执
```
/// 发送在线消息ACK回执
- (void)sendOnlineAck:(NSString *)msgID type:(int32_t)type;
```

- 发送离线消息ACK回执
```
/// 发送离线消息ACK回执
- (void)sendOfflineAck:(NSString *)msgID type:(int32_t)type;
```

- 离线消息发送批量回执
```
/// 离线消息发送批量回执
- (void)sendOfflineMessagesAck:(NSArray *)msgIds;
```


3. 设置消息监听对象用于接受消息
```
/// 设置接受消息的代理
[[LMConnectIMChater sharedManager] addReciveMessageDelegate:self];


/// 协议方法
@protocol LMConnectIMChaterDelegate <NSObject>
/// 交易通知
- (void)transactionNoticeDidReceive:(NoticeMessage *)notice;
/// 接收到消息
- (void)messagesDidReceive:(NSArray <LMMessage *> *)msgs;
/// 消息已读
- (void)messagesDidRead:(NSArray <MessageDidRead *> *)messageIds;
/// 群组创建消息
- (void)createGroupDidReceive:(NSArray<CreateGroupMessage *> *)inviteGroups;
@end
```


### 消息DB数据管理
本SDK不处理数据存储，用户如需使用数据存储，可自行实现协议方法
1. 消息数据处理的基本方法，用户可更具需求，自行创建一个数据管理工具，实现该协议方法
```
@protocol MessageDBManageDelegate <NSObject>
/// 保存消息
- (void)saveMessage:(LMMessage *)message;
/// 保存消息
- (void)batchSaveMessage:(NSArray <LMMessage *>*)messagees;
/// 更新消息状态
- (void)updateMessageStatus:(LMMessageStatus)status withMessageOwer:(NSString *)msgOwer messageId:(NSString *)messageId;
- (NSArray <LMMessage *>*)fetchMessageFromTime:(NSDate *)lastMessageTime limit:(int)limit;
@end
```

2. 配置和获取IMSdk的数据管理器
```
/// 获取数据管理器
- (id <MessageDBManageDelegate>)messageDBManager;

/// 配置数据管理器
- (void)configMessageDBManager:(id<MessageDBManageDelegate>)msgDbManager;
```


### 用户管理
> 说明：
> typedef void (^SocketCallback)(id data,NSError *error);
- 更新用户昵称和是否是常用联系人
```
- (void)updateUserRemark:(NSString *)remark common:(BOOL)common userId:(NSString *)uid complete:(SocketCallback)complete;
```

- 删除好友关系
```
- (void)deleteFriendWithUid:(NSString *)uid complete:(SocketCallback)complete;
```

- 发送添加好友请求
```
- (void)sendRequestToUid:(NSString *)uid source:(int)source message:(NSString *)requestMessage complete:(SocketCallback)complete;
```

- 获取好友列表
```
/// fetch firend list
- (void)friendListWithVersion:(NSString *)version comlete:(SocketCallback)complete;
```

- 接受好友请求
```
/// accept some connect user request
- (void)acceptFriendRequest:(NSString *)uid source:(int)source comlete:(SocketCallback)complete;
```

- 设置推荐好友不再感兴趣
```
/// set recomand user no more interest
- (void)recommandFriendNoInterestWithUid:(NSString *)uid comlete:(SocketCallback)complete;
```

### 领取外部红包和转账

- 领取外部转账
```
/// receive url transfer with token
- (void)reciveMoneyWithToken:(NSString *)token complete:(SocketCallback)complete;
```

- 领取外部红包
```
/// receive url luckypackage with token
- (void)openRedPacketWithToken:(NSString *)token complete:(SocketCallback)complete;
```


### 加密会话Session
- 上传会话Session
```
/// upload a new chatcookie
- (void)uploadCookieWithComplete:(SocketCallback)complete;
```

- 获取好友的会话Session
```
/// fetch friend chatcookie ,pubkey used to sign.
- (void)friendChatCookieWithUid:(NSString *)uid pubkey:(NSString *)pubkey complete:(SocketCallback)complete;
```

- 设置会话免扰
```
/// set chat session mute or not mute
- (void)sessionMute:(BOOL)mute uid:(NSString *)uid complete:(SocketCallback)complete;
```


### APNS推送
- 配置Devicetoken
```
/// register device token for apns
- (void)signDeviceToken:(NSString *)deviceToken complete:(SocketCallback)complete;
```

- 移除Devicetoken，用户退出
```
/// logout and resign apns token
- (void)resignDeviceToken:(NSString *)deviceToken complete:(SocketCallback)complete;
```

- 同步消息未读条数
```
/// sync badge number
- (void)syncBadgeNumber:(int)badgeNumber;
```


