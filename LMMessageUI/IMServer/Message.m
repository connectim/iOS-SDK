/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "Message.h"
#import "LMMessageTool.h"
#import "NSData+Hash.h"
#import "LMEncryptKit.h"
#import "LMConnectIMChater.h"

#define SOCKET_HEAD_LEN 13

@implementation Message


- (instancetype)init {
    if (self = [super init]) {
        self.msgIdentifer = [LMMessageTool generateMessageId];
    }

    return self;
}

static inline unsigned int bswap_32(unsigned int v) {
    return ((v & 0xff) << 24) | ((v & 0xff00) << 8) |
            ((v & 0xff0000) >> 8) | (v >> 24);
}


- (NSMutableData *)pack {

    NSMutableData *dataM = [[NSMutableData alloc] init];

    //ver
    unsigned char version = 0x01;
    NSData *versionData = [NSData dataWithBytes:&version length:sizeof(version)];
    [dataM appendData:versionData];

    //type
    NSData *typeData = [NSData dataWithBytes:&_typechar length:sizeof(_typechar)];
    [dataM appendData:typeData];


    NSData *data = (NSData *) self.body;
    if (![data isKindOfClass:[NSData class]]) {
        return [NSMutableData data];
    }
    if (!data) {
        data = [NSData data];
    }
    int len = (int) data.length;
    //data len
    int lenR = bswap_32(len);
    NSData *lenData = [NSData dataWithBytes:&lenR length:sizeof(lenR)];
    [dataM appendData:lenData];

    //extension
    NSData *extensionData = [NSData dataWithBytes:&_extension length:sizeof(_extension)];
    [dataM appendData:extensionData];

    //salt
    NSData *saltData = [[LMEncryptKit createRandom512bits] subdataWithRange:NSMakeRange(0, 4)];
    [dataM appendData:saltData];

    // ，1 + 4 + 1 + 4
    NSMutableData *checkData = [NSMutableData dataWithData:[dataM subdataWithRange:NSMakeRange(1, 10)]];
    UInt8 j = 0xc0;
    NSData *data1 = [[NSData alloc] initWithBytes:&j length:sizeof(j)];
    [checkData appendData:data1];

    UInt8 i = 0x2E;
    NSData *data2 = [[NSData alloc] initWithBytes:&i length:sizeof(i)];
    [checkData appendData:data2];

    UInt8 n = 0xC7;

    NSData *data3 = [[NSData alloc] initWithBytes:&n length:sizeof(n)];
    [checkData appendData:data3];

    NSData *checkDataMd5 = [checkData md5Data];
    NSData *checkTwoBytes = [checkDataMd5 subdataWithRange:NSMakeRange(0, 2)];

    //check bytes
    [dataM appendData:checkTwoBytes];

    //data
    [dataM appendData:data];
    return dataM;
}

- (BOOL)unpack:(NSData *)data {
    unsigned char type;
    unsigned char extension;
    int lenInt;

    [[data subdataWithRange:NSMakeRange(0, 1)] getBytes:&type length:sizeof(type)];
    _typechar = type;
    [[data subdataWithRange:NSMakeRange(5, 1)] getBytes:&extension length:sizeof(extension)];
    _extension = extension;

    [[data subdataWithRange:NSMakeRange(1, 4)] getBytes:&lenInt length:sizeof(lenInt)];
    lenInt = bswap_32(lenInt);
    NSData *resultData = [data subdataWithRange:NSMakeRange(SOCKET_HEAD_LEN - 1, lenInt)];
    switch (type) {
        case BM_SERVER_ERROR_TYPE:
            [self handlErrorWithExtension:extension];
            return YES;
            break;

        case BM_COMMAND_TYPE:
            [self handlCommandWithExtension:extension resultData:resultData];
            return YES;
            break;

        case BM_IM_TYPE:
            [self handlIMMessageWithExtension:extension resultData:resultData];
            return YES;
            break;
        case BM_ACK_TYPE:
            [self handlAckWithExtension:extension resultData:resultData];
            return YES;
            break;
        case BM_CUTOFFINE_CONNECT_TYPE:
            [self handCutOffByServer:extension resultData:resultData];
            return YES;
            break;

        default:
            if (type == BM_HEARTBEAT_TYPE && extension == BM_HEARTBEAT_EXT) {
                return YES;
            } else if (type == BM_HANDSHAKE_TYPE && extension == BM_HANDSHAKE_EXT) {
                self.body = [IMResponse parseFromData:resultData error:nil];
                return YES;
            } else if (type == BM_HANDSHAKE_TYPE && extension == BM_HANDSHAKEACK_EXT) {
                self.body = [IMResponse parseFromData:resultData error:nil];
                return YES;
            } else {
            }
            break;
    }
    return YES;
}


- (void)handlErrorWithExtension:(unsigned char)extension {
    switch (extension) {
        case BM_NO_RELATIONSHIP_EXT:
            break;
        default:
            break;
    }
}

- (void)handlAckWithExtension:(unsigned char)extension resultData:(NSData *)resultData {
    switch (extension) {
        case BM_ACK_EXT: {
            IMTransferData *imTransfer = [IMTransferData parseFromData:resultData error:nil];
            if ([LMEncryptKit verfiySign:imTransfer.sign signedData:[imTransfer.cipherData.data hash256String] pubkey:[LMConnectIMChater sharedManager].chatSessionManager.connectServerPubkey]) {
                NSData *decodeData = [LMMessageTool decodeGcmDataWithEcdhKey:[LMConnectIMChater sharedManager].chatSessionManager.socketExtensionECDH GcmData:imTransfer.cipherData havePlainData:NO];
                Ack *ack = [Ack parseFromData:decodeData error:nil];
                self.body = ack;
            }
        }
            break;
        default:
            
            break;
    }
}

- (void)handCutOffByServer:(unsigned char)extension resultData:(NSData *)resultData {
    switch (extension) {
        case BM_CUTOFFINE_CONNECT_EXT: {
            IMTransferData *imTransfer = [IMTransferData parseFromData:resultData error:nil];
            if ([LMEncryptKit verfiySign:imTransfer.sign signedData:[imTransfer.cipherData.data hash256String] pubkey:[LMConnectIMChater sharedManager].chatSessionManager.connectServerPubkey]) {
                NSData *decodeData = [LMMessageTool decodeGcmDataWithEcdhKey:[LMConnectIMChater sharedManager].chatSessionManager.socketExtensionECDH GcmData:imTransfer.cipherData havePlainData:NO];
                NSError *erro = nil;
                QuitMessage *quitMessage = [QuitMessage parseFromData:decodeData error:&erro];
                if (!erro) {
                    self.body = quitMessage;
                } else {
                    
                }
            }
        }
            break;
        default:
            break;
    }
}

- (void)handlCommandWithExtension:(unsigned char)extension resultData:(NSData *)resultData {
    switch (extension) {
        case BM_GETOFFLINE_EXT:
        case BM_BINDDEVICETOKEN_EXT:
        case BM_UNBINDDEVICETOKEN_EXT:
        case BM_FRIENDLIST_EXT:
        case BM_DELETE_FRIEND_EXT:
        case BM_ACCEPT_NEWFRIEND_EXT:
        case BM_NEWFRIEND_EXT:
        case BM_SET_FRIENDINFO_EXT:
        case BM_COMMON_GROUP_EXT:
        case BM_OFFLINE_CMD_EXT:
        case BM_GROUPINFO_CHANGE_EXT:
        case BM_CREATE_SESSION:
        case BM_SETMUTE_SESSION:
        case BM_DELETE_SESSION:
        case BM_SYNCBADGENUMBER_EXT:
        case BM_OUTER_TRANSFER_EXT:
        case BM_OUTER_REDPACKET_EXT:
        case BM_INVITE_TO_GROUP_EXT:
        case BM_RECOMMADN_NOTINTEREST_EXT:
        case BM_UPLOAD_CHAT_COOKIE_EXT:
        case BM_FRIEND_CHAT_COOKIE_EXT:
        case BM_FROCEUODATA_CHAT_COOKIE_EXT: {
            IMTransferData *imTransfer = [IMTransferData parseFromData:resultData error:nil];
            if ([LMEncryptKit verfiySign:imTransfer.sign signedData:[imTransfer.cipherData.data hash256String] pubkey:[LMConnectIMChater sharedManager].chatSessionManager.connectServerPubkey]) {
                NSData *decodeData = [LMMessageTool decodeGcmDataWithEcdhKey:[LMConnectIMChater sharedManager].chatSessionManager.socketExtensionECDH GcmData:imTransfer.cipherData havePlainData:YES];
                self.body = decodeData;
            }
        }
            break;
        default:
            break;
    }
}

- (void)handlIMMessageWithExtension:(unsigned char)extension resultData:(NSData *)resultData {
    
    IMTransferData *imTransfer = [IMTransferData parseFromData:resultData error:nil];
    if ([LMEncryptKit verfiySign:imTransfer.sign signedData:[imTransfer.cipherData.data hash256String] pubkey:[LMConnectIMChater sharedManager].chatSessionManager.connectServerPubkey]) {
        NSData *data = [LMMessageTool decodeGcmDataWithEcdhKey:[LMConnectIMChater sharedManager].chatSessionManager.socketExtensionECDH GcmData:imTransfer.cipherData havePlainData:YES];
        switch (extension) {
            case BM_IM_SEND_GROUPINFO_EXT:
            case BM_IM_GROUPMESSAGE_EXT:
            case BM_IM_MESSAGE_ACK_EXT:
            case BM_IM_NO_RALATIONSHIP_EXT:
            case BM_IM_EXT: {
                MessagePost *post = [MessagePost parseFromData:data error:nil];
                self.body = post;
            }
                break;
            case BM_IM_ROBOT_EXT: {
                MSMessage *post = [MSMessage parseFromData:data error:nil];
                self.body = post;
            }
                break;
                
            case BM_SERVER_NOTE_EXT: {
                NoticeMessage *post = [NoticeMessage parseFromData:data error:nil];
                self.body = post;
            }
                break;
                break;
            case BM_IM_UNARRIVE_EXT: {
                RejectMessage *post = [RejectMessage parseFromData:data error:nil];
                self.body = post;
            }
                break;
            default:
                break;
        }
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%d extension:%d", self.typechar, self.extension];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"debug: type:%d extension:%d", self.typechar, self.extension];
}

@end
