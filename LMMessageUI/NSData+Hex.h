//
//  NSData+Hex.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Hex)

- (NSString *)lmHexString;

- (NSData *)orxWithData:(NSData *)data;

@end
