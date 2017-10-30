//
//  LMCommandAdapter.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCommandAdapter.h"
#import "LMMessageTool.h"

@implementation LMCommandAdapter

+ (CommandMessage *)sendAdapterWithExtension:(unsigned char)extension sendData:(GPBMessage *)sendData {
    if (sendData) {
        //command
        Command *command = [[Command alloc] init];
        command.msgId = [LMMessageTool generateMessageId];
        command.detail = sendData.data;
        //transferData
        IMTransferData *request = [LMMessageTool makeTransferDataWithExtensionPass_Data:command.data];
        CommandMessage *commandMsg = [CommandMessage new];
        commandMsg.commandId = command.msgId;
        commandMsg.transferData = request;
        commandMsg.commandExtension = extension;
        
        return commandMsg;
    } else {
        CommandMessage *commandMsg = [CommandMessage new];
        commandMsg.commandId = [LMMessageTool generateMessageId];
        commandMsg.commandExtension = extension;
        return commandMsg;
    }
}

@end
