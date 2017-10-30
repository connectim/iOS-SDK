//
//  LMMessageLayout.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageLayout.h"

@implementation LMMessageLayout

- (instancetype)initWithMessage:(LMMessage *)message sender:(LMUserInfo *)sender {
    if (self = [super init]) {
        self.chatMessage = message;
        self.sender = sender;
        self.meuns = [NSMutableArray array];
        [self layout];
    }
    return self;
}

- (void)layout {
    _rowHeight = 0;
    _msgContentWidth = 0;
    _msgContentHeight = 0;
    _msgSenderNameLayout = nil;
    _textMsgLayout = nil;
    _rowHeight += MSGCellMargin;
    
    if (self.sender) {
        CGFloat w = kScreenWidth - 2 * MSGAvatarHeight;
        YYTextContainer *container = [YYTextContainer new];
        container.size = CGSizeMake(w, HUGE);
        NSMutableAttributedString *nameStr = [[NSMutableAttributedString alloc] initWithString:self.sender.username];
        nameStr.font = [UIFont systemFontOfSize:14];
        _msgSenderNameLayout = [YYTextLayout layoutWithContainer:container text:nameStr];
        _rowHeight += _msgSenderNameLayout.textBoundingSize.height;
        _rowHeight += MSGCellMargin;
    }
    
    YYTextContainer *container = [YYTextContainer new];
    switch (self.chatMessage.msgType) {
        case LMMessageTypeText:
        {
            CGFloat w = MSGMaxTextMsgW;
            TextMessage *text = (TextMessage *)self.chatMessage.msgContent;
            container.size = CGSizeMake(w, HUGE);
            NSMutableAttributedString *textStr = [self _textWithMsgText:text.content fontSize:MSGTitleFont textColor:[UIColor blackColor]];
            _textMsgLayout = [YYTextLayout layoutWithContainer:container text:textStr];
            
            _msgContentHeight = _textMsgLayout.textBoundingSize.height + 2 * MSGCellMargin;
            if (_msgContentHeight < MSGAvatarHeight) {
                _msgContentHeight = MSGAvatarHeight;
            }
            _msgContentWidth = _textMsgLayout.textBoundingSize.width + 2 * MSGCellMargin + MSGBubbleHorn;
            if (_msgContentWidth < MSGAvatarHeight + MSGBubbleHorn) {
                _msgContentWidth = MSGAvatarHeight + MSGBubbleHorn;
            }
            [_meuns addObject:LMMessageMeunCopy];
            [_meuns addObject:LMMessageMeunReweet];
            [_meuns addObject:LMMessageMeunDelete];
        }
            break;
            
        case LMMessageTypeImage:
        {
            CGFloat maxWH = MSGMaxImageMsgWH;
            PhotoMessage *image = (PhotoMessage *)self.chatMessage.msgContent;
            if (image.imageWidth> maxWH &&
                image.imageWidth >= image.imageHeight) {
                _msgContentWidth = maxWH;
                _msgContentHeight = _msgContentWidth * image.imageHeight / image.imageWidth;
            } else if (image.imageHeight > maxWH &&
                       image.imageHeight >= image.imageWidth) {
                _msgContentHeight = maxWH;
                _msgContentWidth = _msgContentHeight * image.imageWidth / image.imageHeight;
            } else {
                _msgContentHeight = image.imageWidth;
                _msgContentWidth = image.imageHeight;
            }
            [_meuns addObject:LMMessageMeunReweet];
            [_meuns addObject:LMMessageMeunDelete];
        }
            break;
            
      case LMMessageTypeVideo:
        {
            CGFloat maxWH = MSGMaxImageMsgWH;
            VideoMessage *video = (VideoMessage *)self.chatMessage.msgContent;
            if (video.imageWidth> maxWH &&
                video.imageWidth >= video.imageHeight) {
                _msgContentWidth = maxWH;
                _msgContentHeight = _msgContentWidth * video.imageHeight / video.imageWidth;
            } else if (video.imageHeight > maxWH &&
                       video.imageHeight >= video.imageWidth) {
                _msgContentHeight = maxWH;
                _msgContentWidth = _msgContentHeight * video.imageWidth / video.imageHeight;
            } else {
                _msgContentHeight = video.imageWidth;
                _msgContentWidth = video.imageHeight;
            }
            
            CGFloat fontSize = 10;
            int fileSize = video.size;
            float nM = fileSize / 1024 / 1024.f;
            int nK = (fileSize % (1024 * 1024)) / 1024;
            NSString *videoSize = [NSString stringWithFormat:@"%dkb", nK];
            if (nM >= 1) {
                videoSize = [NSString stringWithFormat:@"%.1fM", nM];
            }
            
            NSMutableAttributedString *videoSizeAtt = [[NSMutableAttributedString alloc] initWithString:videoSize];
            videoSizeAtt.font = [UIFont systemFontOfSize:fontSize];
            videoSizeAtt.color = [UIColor whiteColor];
            
            YYTextContainer *fileSizeContainer = [YYTextContainer new];
            fileSizeContainer.size = CGSizeMake(_msgContentWidth * 0.5, HUGE);
            _videoSizeLayout = [YYTextLayout layoutWithContainer:fileSizeContainer text:videoSizeAtt];
            
            
            NSString *videoTimeString = [NSString stringWithFormat:@"00:%02d", video.timeLength];
            if (video.timeLength > 60 && video.timeLength <= 60 * 60) {
                videoTimeString = [NSString stringWithFormat:@"%02d:%02d", video.timeLength / 60, video.timeLength % 60];
            } else if (video.timeLength > 60 * 60) {
                videoTimeString = [NSString stringWithFormat:@"%02d:%02d:%02d", video.timeLength / 60 / 60, video.timeLength % (60 * 60) / 60, video.timeLength % 60 % 60];
            }
            
            NSMutableAttributedString *videoTimeAtt = [[NSMutableAttributedString alloc] initWithString:videoTimeString];
            videoTimeAtt.font = [UIFont systemFontOfSize:fontSize];
            videoTimeAtt.color = [UIColor whiteColor];
            
            YYTextContainer *videoTimeContainer = [YYTextContainer new];
            videoTimeContainer.size = CGSizeMake(_msgContentWidth * 0.5, HUGE);
            _videoTimeLayout = [YYTextLayout layoutWithContainer:videoTimeContainer text:videoTimeAtt];
            
            [_meuns addObject:LMMessageMeunReweet];
            [_meuns addObject:LMMessageMeunDelete];
            [_meuns addObject:LMMessageMeunSave];
        }
            break;
        case LMMessageTypeTip:
        {
            NotifyMessage *tip = (NotifyMessage *)self.chatMessage.msgContent;
            container.size = CGSizeMake(MSGMsgMaxWidth, HUGE);
            NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:tip.content];
            textStr.font = [UIFont systemFontOfSize:MSGTipFont];
            textStr.color = [UIColor whiteColor];
            _tipLayout = [YYTextLayout layoutWithContainer:container text:textStr];
            
            _msgContentHeight = _tipLayout.textBoundingSize.height + MSGCellMargin;
            _msgContentWidth = _tipLayout.textBoundingSize.width + 2 * MSGCellMargin;
        }
            break;
            
        case LMMessageTypeTime:
        {
            TimeMessage *time = (TimeMessage *)self.chatMessage.msgContent;
            container.size = CGSizeMake(MSGMsgMaxWidth, HUGE);
            NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:time.time];
            textStr.font = [UIFont systemFontOfSize:MSGTipFont];
            textStr.color = [UIColor whiteColor];
            _tipLayout = [YYTextLayout layoutWithContainer:container text:textStr];
            
            _msgContentHeight = _tipLayout.textBoundingSize.height + MSGCellMargin;
            _msgContentWidth = _tipLayout.textBoundingSize.width + 2 * MSGCellMargin;
        }
            break;

        default:
        {
            _chatMessage.msgType = LMMessageTypeTip;
            container.size = CGSizeMake(MSGMsgMaxWidth, HUGE);
            NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:@"消息不能解析"];
            textStr.font = [UIFont systemFontOfSize:MSGTipFont];
            textStr.color = [UIColor whiteColor];
            
            // 高亮状态的背景
            YYTextBorder *highlightBorder = [YYTextBorder new];
            highlightBorder.insets = UIEdgeInsetsMake(-2, 0, -2, 0);
            highlightBorder.cornerRadius = 3;
            highlightBorder.fillColor = MSGHighlightColor;
            
            NSMutableAttributedString *tapUpdateText = [[NSMutableAttributedString alloc] initWithString:@"点击升级到最新版本"];
            tapUpdateText.font = [UIFont systemFontOfSize:MSGTipFont];
            tapUpdateText.color = MSGBlueColor;
            // 高亮状态
            YYTextHighlight *highlight = [YYTextHighlight new];
            [highlight setBackgroundBorder:highlightBorder];
            highlight.userInfo = @{MSGUpdateAppName:@"update"};
            [tapUpdateText setTextHighlight:highlight range:tapUpdateText.rangeOfAll];
            
            
            [textStr appendAttributedString:tapUpdateText];
            _tipLayout = [YYTextLayout layoutWithContainer:container text:textStr];
            
            _msgContentHeight = _tipLayout.textBoundingSize.height + MSGCellMargin;
            _msgContentWidth = _tipLayout.textBoundingSize.width + 2 * MSGCellMargin;
        }
            break;
    }
    
    _rowHeight += _msgContentHeight;
    _rowHeight += MSGCellMargin;
    
    if (_rowHeight < MSGCellMargin * 2 + MSGAvatarHeight &&
        _chatMessage.msgType != LMMessageTypeTip &&
        _chatMessage.msgType != LMMessageTypeTime) {
        _rowHeight = MSGCellMargin * 2 + MSGAvatarHeight;
    }
}


- (NSMutableAttributedString *)_textWithMsgText:(NSString *)msgText
                                       fontSize:(CGFloat)fontSize
                                      textColor:(UIColor *)textColor {
    if (!msgText) return nil;
    
    NSMutableString *string = msgText.mutableCopy;
    if (string.length == 0) return nil;
    // 字体
    UIFont *font = [UIFont fontWithName:@"Verdana" size:fontSize];
    // 高亮状态的背景
    YYTextBorder *highlightBorder = [YYTextBorder new];
    highlightBorder.insets = UIEdgeInsetsMake(-2, 0, -2, 0);
    highlightBorder.cornerRadius = 3;
    highlightBorder.fillColor = MSGHighlightColor;
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:string];
    text.font = font;
    text.color = textColor;
    
    /// 链接
    NSString *regulaStr = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z0-9]{1,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z0-9]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    NSError *error = NULL;
    // 根据匹配条件，创建了一个正则表达式
    NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                              options:NSRegularExpressionCaseInsensitive                                                            error:&error];
    if (!urlRegex) {
    } else {
        NSArray *allMatches = [urlRegex matchesInString:text.string options:NSMatchingReportCompletion range:NSMakeRange(0, text.string.length)];
        for (NSTextCheckingResult *match in allMatches) {
            NSString *substrinsgForMatch2 = [text.string substringWithRange:match.range];
            NSMutableAttributedString *one = [[NSMutableAttributedString alloc] initWithString:substrinsgForMatch2];
            // 利用YYText设置一些文本属性
            one.font = font;
            one.color = MSGBlueColor;
            // 高亮状态
            YYTextHighlight *highlight = [YYTextHighlight new];
            [highlight setBackgroundBorder:highlightBorder];
            // 数据信息，用于稍后用户点击
            highlight.userInfo = @{MSGLinkURLName : one.string};
            [one setTextHighlight:highlight range:one.rangeOfAll];
            // 根据range替换字符串
            [text replaceCharactersInRange:match.range withAttributedString:one];
        }
    }
    
    /// 电话号码
    regulaStr = @"((\\d{11})|^((\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1})|(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1}))$)";
    error = NULL;
    // 根据匹配条件，创建了一个正则表达式
    NSRegularExpression *phoneRegex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                                options:NSRegularExpressionCaseInsensitive                                                            error:&error];
    if (!phoneRegex) {
    } else {
        NSArray *allMatches = [phoneRegex matchesInString:text.string options:NSMatchingReportCompletion range:NSMakeRange(0, text.string.length)];
        for (NSTextCheckingResult *match in allMatches) {
            NSString *substrinsgForMatch2 = [text.string substringWithRange:match.range];
            NSMutableAttributedString *one = [[NSMutableAttributedString alloc] initWithString:substrinsgForMatch2];
            // 利用YYText设置一些文本属性
            one.font = font;
            one.color = MSGBlueColor;
            // 高亮状态
            YYTextHighlight *highlight = [YYTextHighlight new];
            [highlight setBackgroundBorder:highlightBorder];
            // 数据信息，用于稍后用户点击
            highlight.userInfo = @{MSGLinkPhoneName : one.string};
            [one setTextHighlight:highlight range:one.rangeOfAll];
            // 根据range替换字符串
            [text replaceCharactersInRange:match.range withAttributedString:one];
        }
    }
    
    /// 邮箱
    regulaStr = @"[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)+";
    error = NULL;
    // 根据匹配条件，创建了一个正则表达式
    NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                                options:NSRegularExpressionCaseInsensitive                                                            error:&error];
    if (!emailRegex) {
    } else {
        NSArray *allMatches = [emailRegex matchesInString:text.string options:NSMatchingReportCompletion range:NSMakeRange(0, text.string.length)];
        for (NSTextCheckingResult *match in allMatches) {
            NSString *substrinsgForMatch2 = [text.string substringWithRange:match.range];
            NSMutableAttributedString *one = [[NSMutableAttributedString alloc] initWithString:substrinsgForMatch2];
            // 利用YYText设置一些文本属性
            one.font = font;
            one.color = MSGBlueColor;
            // 高亮状态
            YYTextHighlight *highlight = [YYTextHighlight new];
            [highlight setBackgroundBorder:highlightBorder];
            // 数据信息，用于稍后用户点击
            highlight.userInfo = @{MSGLinkEmailName : one.string};
            [one setTextHighlight:highlight range:one.rangeOfAll];
            // 根据range替换字符串
            [text replaceCharactersInRange:match.range withAttributedString:one];
        }
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^ \\[\\]]+?\\]" options:kNilOptions error:NULL];
    
    // 匹配 [表情]
    NSArray<NSTextCheckingResult *> *emoticonResults = [regex matchesInString:text.string options:kNilOptions range:text.rangeOfAll];
    NSUInteger emoClipLength = 0;
    for (NSTextCheckingResult *emo in emoticonResults) {
        if (emo.range.location == NSNotFound && emo.range.length <= 1) continue;
        NSRange range = emo.range;
        range.location -= emoClipLength;
        if ([text attribute:YYTextHighlightAttributeName atIndex:range.location]) continue;
        if ([text attribute:YYTextAttachmentAttributeName atIndex:range.location]) continue;
        NSString *emoString = [text.string substringWithRange:range];
        //// 在这里获取对应的表情图片即可 ，作为演示，我用默认图片代替表情
        UIImage *image = [UIImage imageNamed:@"msg_inputbar_emoji"];
        if (!image) continue;
        
        NSAttributedString *emoText = [NSAttributedString attachmentStringWithEmojiImage:image fontSize:fontSize];
        [text replaceCharactersInRange:range withAttributedString:emoText];
        emoClipLength += range.length - 1;
    }
    return text;
}


@end
