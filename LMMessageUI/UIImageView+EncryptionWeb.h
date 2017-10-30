//
//  UIImageView+EncryptionWeb.h
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (EncryptionWeb)

- (void)setImageWithURL:(NSURL *)url ECDHKey:(NSData *)ECDHKey;

@end
