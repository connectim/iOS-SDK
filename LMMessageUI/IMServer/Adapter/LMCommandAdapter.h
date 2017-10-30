//
//  LMCommandAdapter.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.pbobjc.h"

@interface LMCommandAdapter : NSObject

+ (CommandMessage *)sendAdapterWithExtension:(unsigned char)extension sendData:(GPBMessage *)sendData;

@end
