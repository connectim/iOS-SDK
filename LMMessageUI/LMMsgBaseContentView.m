//
//  LMMsgBaseContentView.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/19.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMsgBaseContentView.h"
#import "LMMessageBaseCell.h"

@interface LMMsgBaseContentView ()

@property (nonatomic ,strong) UIImageView *highlightedImageView;

@end

@implementation LMMsgBaseContentView

- (instancetype)initWithLayout:(LMMessageLayout *)msgLayout {
    if (self = [super initWithFrame:CGRectMake(0, 0, msgLayout.msgContentWidth, msgLayout.msgContentHeight)]) {
        self.msgLayout = msgLayout;
        self.bubbleImage = [[UIImageView alloc] init];
        self.bubbleImage.frame = self.bounds;
        /// 文本消息蓝色的可点击
        self.bubbleImage.userInteractionEnabled = YES;
        [self addSubview:self.bubbleImage];
        
        self.highlightedImageView = [[UIImageView alloc] init];
        self.highlightedImageView.frame = self.bubbleImage.bounds;
        [self.bubbleImage addSubview:self.highlightedImageView];
        
        [self configBubble];
        
    }
    return self;
}

- (void)tapMsgContent {
    
}

- (void)setMsgLayout:(LMMessageLayout *)msgLayout {
    _msgLayout = msgLayout;
    self.size = CGSizeMake(msgLayout.msgContentWidth, msgLayout.msgContentHeight);
    self.bubbleImage.size = self.size;
    self.highlightedImageView.frame = self.bubbleImage.bounds;
    [self configBubble];
}

- (void)configBubble {
    if (self.msgLayout.chatMessage.sendFromSelf) {
        switch (self.msgLayout.chatMessage.msgType) {
            case LMMessageTypeText:{
                self.bubbleImage.image = [UIImage imageNamed:@"message_box_blue"];//[self resizeBubbleImage:@"message_box_blue"];
            }
                break;
            case LMMessageTypeImage:
                self.bubbleImage.image = [self resizeBubbleImage:@"message_box_blue"];
                break;
            case LMMessageTypeVideo:
                self.bubbleImage.image = [self resizeBubbleImage:@"message_box_blue"];
                break;
            default:
                break;
        }
        UIImage *image = [self imageWithName:@"message_box_blue" withColor:[UIColor colorWithRed:135.f / 255 green:206.f / 255 blue:250.f / 255 alpha:0.5]];
        [self.highlightedImageView setHighlightedImage:image];
    } else {
        switch (self.msgLayout.chatMessage.msgType) {
            case LMMessageTypeText:
                self.bubbleImage.image = [UIImage imageNamed:@"reciver_message_white"];//[self resizeBubbleImage:@"reciver_message_white"];
                break;
            case LMMessageTypeImage:
                self.bubbleImage.image = [self resizeBubbleImage:@"reciver_message_white"];
                break;
            case LMMessageTypeVideo:
                self.bubbleImage.image = [self resizeBubbleImage:@"reciver_message_white"];
                break;
            default:
                break;
        }
        UIImage *image = [self imageWithName:@"reciver_message_white" withColor:[UIColor colorWithRed:135.f / 255 green:206.f / 255 blue:250.f / 255 alpha:0.5]];
        [self.highlightedImageView setHighlightedImage:image];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [self.highlightedImageView setHighlighted:highlighted];
}

- (UIImage *)resizeBubbleImage:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    CGSize imageSize = image.size;
    UIImage *resizeImage = [image resizableImageWithCapInsets:UIEdgeInsetsMake(imageSize.height / 3.f * 2, imageSize.width / 2.f, imageSize.height / 3.f * 1, imageSize.width / 2.f) resizingMode:UIImageResizingModeStretch];
    return resizeImage;
}

- (UIImage *)imageWithName:(NSString *)imageName withColor:(UIColor *)color
{
    UIImage *image = [UIImage imageNamed:imageName];
    image = [image imageByFlipVertical];
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage *flippedImage = [UIImage imageWithCGImage:img.CGImage
                                                scale:0 orientation:UIImageOrientationUp];
    CGSize imageSize = flippedImage.size;
    UIImage *resizeImage = [flippedImage resizableImageWithCapInsets:UIEdgeInsetsMake(imageSize.height / 3.f * 2, imageSize.width / 2.f, imageSize.height / 3.f * 1, imageSize.width / 2.f) resizingMode:UIImageResizingModeStretch];
    return resizeImage;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self tapMsgContent];
}

@end
