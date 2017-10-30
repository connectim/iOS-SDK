//
//  NSData+Hex.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "NSData+Hex.h"

@implementation NSData (Hex)

- (NSString *)lmHexString{
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    if (!dataBuffer)
        return [NSString string];
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    return [NSString stringWithString:hexString];
}


- (NSData *)orxWithData:(NSData *)data {
    const char *data1Bytes = [data bytes];
    const char *data2Bytes = [self bytes];
    NSMutableData *xorData = [[NSMutableData alloc] init];
    for (int i = 0; i < data.length; i++){
        const char xorByte = data1Bytes[i] ^ data2Bytes[i];
        [xorData appendBytes:&xorByte length:1];
    }
    return xorData;
}

@end
