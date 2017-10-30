//
//  LMChatMsgUploadManager.m
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMChatMsgUploadManager.h"
#import "LMMessageTool.h"
#import "LMEncryptKit.h"
#import "LMConnectIMChater.h"
#import <AFNetworking/AFNetworking.h>

@interface LMChatMsgUploadManager ()

@property (nonatomic ,strong) AFHTTPSessionManager *uploaderManager;

@end

@implementation LMChatMsgUploadManager

+ (LMChatMsgUploadManager *)shareManager {
    static dispatch_once_t onceToken;
    static LMChatMsgUploadManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[LMChatMsgUploadManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.uploaderManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.uploaderManager.requestSerializer.timeoutInterval = 15;
        self.uploaderManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        NSSet *set = self.uploaderManager.responseSerializer.acceptableContentTypes;
        self.uploaderManager.responseSerializer.acceptableContentTypes = [set setByAddingObject:@"binary/octet-stream"];
        self.uploaderManager.operationQueue.maxConcurrentOperationCount = 9;
    }
    return self;
}


- (void)uploadMainData:(NSData *)mainData minorData:(NSData *)minorData encryptECDH:(NSData *)ecdhkey to:(NSString *)to msgId:(NSString *)msgId chatType:(int)chatType originMsg:(GPBMessage *)originMsg progress:(void (^)(NSString *to,NSString *msgId,CGFloat progress))progress  complete:(void(^)(GPBMessage *originMsg,NSString *to,NSString *msgId,NSError *error))completion {
    
    if (chatType != ChatType_ConnectSystem) {
        ecdhkey = [LMEncryptKit getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[LMMessageTool get64ZeroData]];
        if (!mainData) {
            if (completion) {
                completion(nil,nil,nil,[NSError errorWithDomain:@"" code:-1 userInfo:nil]);
            }
            return;
        }
        GcmData *mainGcmdata = [LMMessageTool encodeData:mainData needPlainData:YES withECDHKey:ecdhkey];
        
        RichMedia *richMedia = [[RichMedia alloc] init];
        richMedia.entity = mainGcmdata.data;
        if (minorData) {
            GcmData *minorGcmdata = [LMMessageTool encodeData:minorData needPlainData:YES withECDHKey:ecdhkey];
            richMedia.thumbnail = minorGcmdata.data;
        }

        GcmData *serverGcmData = [LMMessageTool encodeData:richMedia.data needPlainData:YES withECDHKey:[LMConnectIMChater sharedManager].chatSessionManager.userServerECDH];
        
        MediaFile *mediaFile = [[MediaFile alloc] init];
        mediaFile.pubKey = [LMConnectIMChater sharedManager].chatSessionManager.connectPubkey;
        mediaFile.cipherData = serverGcmData;
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@""]];
        request.timeoutInterval = 15;
        [request setHTTPBody:mediaFile.data];
        [request setHTTPMethod:@"POST"];
        NSURLSessionUploadTask *task;
        
        task = [self.uploaderManager uploadTaskWithStreamedRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            
        }];
        [task resume];
    } else {
        
    }
}

@end
