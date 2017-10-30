//
//  LMMessageViewController.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMMessageViewController.h"
#import "LMMessageConstant.h"
#import "LMMessageHelper.h"
#import "LMMessageBaseCell.h"
#import "UIImageView+EncryptionWeb.h"
#import "NSString+Hex.h"
#import "LMMessageInputBar.h"
#import "LMConnectIMChater.h"
#import "LMMessageTool.h"
#import "LMEncryptKit.h"
#import "NSDate+LMAdd.h"
#import "LMMessageDBManager.h"
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <AVKit/AVKit.h>

@interface LMMessageViewController ()<UITableViewDelegate,UITableViewDataSource,
LMMessageInputBarDelegate,LMConnectIMChaterDelegate,
LMMessageActionDelegate,
MWPhotoBrowserDelegate>

@property (nonatomic ,strong) UITableView *msgTableView;
@property (nonatomic ,strong) LMMessageInputBar *inputBar;
@property (nonatomic ,strong) NSMutableArray *msgArray;

@property (nonatomic ,strong) UserInfo *chatUser;
@property (nonatomic ,strong) UserInfo *loginUser;

@property (nonatomic ,assign) NSTimeInterval lastMsgTime;
@property (nonatomic ,strong) NSMutableArray *assetArray;

@end

@implementation LMMessageViewController


#pragma mark @protocol YYTextKeyboardObserver
- (void)keyboardChangedWithTransition:(YYTextKeyboardTransition)transition {
    CGRect toFrame = [[YYTextKeyboardManager defaultManager] convertRect:transition.toFrame toView:self.view];
    if (transition.animationDuration == 0) {
        self.inputBar.bottom = CGRectGetMinY(toFrame);
        self.msgTableView.bottom = self.inputBar.top;
    } else {
        [UIView animateWithDuration:transition.animationDuration delay:0 options:transition.animationOption | UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.inputBar.bottom = CGRectGetMinY(toFrame);
            self.msgTableView.bottom = self.inputBar.top;
        } completion:NULL];
    }
    
    [self scrollTableView];
}

- (void)scrollTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.msgTableView reloadData];
        
        BOOL isNeedScrollToBottom = NO;
        if (self.msgTableView.contentOffset.y >= self.msgTableView.contentSize.height - 2 * self.msgTableView.height) {
            isNeedScrollToBottom = YES;
        }
        if (isNeedScrollToBottom) {
            [self scrollToBottom:YES];
        }
    });
}

- (void)scrollToBottom:(BOOL)animated {
    if ([self.msgArray count] == 0)
        return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.msgArray count] - 1 inSection:0];
    UITableViewCell *cell = [self.msgTableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        CGFloat offsetY = self.msgTableView.contentSize.height + self.msgTableView.contentInset.bottom - CGRectGetHeight(self.msgTableView.frame);
        if (offsetY < -self.msgTableView.contentInset.top)
            offsetY = -self.msgTableView.contentInset.top;
        [self.msgTableView setContentOffset:CGPointMake(0, offsetY) animated:animated];
    } else {
        [self.msgTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)inputBarTopChange:(CGFloat)top animationDuration:(CGFloat)animationDuration {
    if (animationDuration == 0) {
        self.inputBar.top = top;
        self.msgTableView.bottom = self.inputBar.top;
    } else {
        [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.inputBar.top = top;
            self.msgTableView.bottom = self.inputBar.top;
        } completion:NULL];
    }
    [self scrollTableView];
}

/// LMMessageInputBarDelegate
- (void)inputBarSendText:(NSString *)msgtext {
    LMMessage *msg = [LMMessage new];
    msg.msgOwer = self.chatUser.uid;
    msg.msgId = [LMMessageTool generateMessageId];
    msg.senderId = self.loginUser.uid;
    msg.createTime = [NSDate date];
    msg.sendFromSelf = YES;
    msg.msgType = LMMessageTypeText;
    TextMessage *text = [TextMessage new];
    text.content = msgtext;
    msg.msgContent = text;
    LMMessageLayout *msgLayout = [[LMMessageLayout alloc] initWithMessage:msg sender:nil];
    msgLayout.sendAvatar = self.loginUser.avatar;
    [self.msgArray addObject:msgLayout];
    
    /// 发送消息
    [[LMConnectIMChater sharedManager] sendP2PMessageInfo:msg progress:^(NSString *to, NSString *msgId, CGFloat progress) {
        
    } complete:^(ChatMessage *chatMsg, NSError *error) {
        
    }];
    [self scrollTableView];
}


#pragma LMConnectIMChaterDelegate
- (void)messagesDidRead:(NSArray<MessageDidRead *> *)messageIds {
    
}

- (void)messagesDidReceive:(NSArray<LMMessage *> *)msgs {
    for (LMMessage *msg in msgs) {
        LMMessageLayout *msgLayout = [[LMMessageLayout alloc] initWithMessage:msg sender:nil];
        msgLayout.sendAvatar = self.chatUser.avatar;
        msgLayout.ECDHKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:self.chatUser.pubKey];
        if (msg.createTime.timeIntervalSince1970 - self.lastMsgTime > 10) {
            self.lastMsgTime = msg.createTime.timeIntervalSince1970;
            [self insertTime];
        }
        [self.msgArray addObject:msgLayout];
    }
    [self scrollTableView];
}

- (void)createGroupDidReceive:(NSArray<CreateGroupMessage *> *)inviteGroups {
    
}

- (void)transactionNoticeDidReceive:(NoticeMessage *)notice {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.chatUser = [UserInfo new];
    self.chatUser.username = @"M哦打个";
    self.chatUser.uid = @"02edcd543967c989668e4312fb0c0a3fdcb3e5dea7e73c3fba7261fe2f491166b4";
    self.chatUser.pubKey = @"02edcd543967c989668e4312fb0c0a3fdcb3e5dea7e73c3fba7261fe2f491166b4";
    self.chatUser.avatar = @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=602288768,1056696022&fm=27&gp=0.jpg";
    
    self.loginUser = [UserInfo new];
    self.loginUser.username = @"莫灰心";
    self.loginUser.uid = @"0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0";
    self.loginUser.pubKey = @"0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0";
    self.loginUser.avatar = @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=1762973822,121126736&fm=27&gp=0.jpg";
    
    self.msgArray = [NSMutableArray array];
    self.msgTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.msgTableView.delegate = self;
    self.msgTableView.dataSource = self;
    self.msgTableView.backgroundColor = MSGChatBackColor;
    self.msgTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.msgTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    [LMMessageHelper regisgerMsgCellWithTableView:self.msgTableView];
    [self.view addSubview:self.msgTableView];
    
    
    self.inputBar = [[LMMessageInputBar alloc] init];
    self.inputBar.top = kScreenHeight - MSGInPutbarHeight;
    self.inputBar.delegate = self;
    [self.view addSubview:self.inputBar];
    
    self.msgTableView.bottom = self.inputBar.top;


    UISwitch *switchBtn = [[UISwitch alloc] init];
    [switchBtn addTarget:self action:@selector(showHidenSenderName:) forControlEvents:UIControlEventValueChanged];
    self.title = @"点击Switch显示发送者名字";
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:switchBtn];
    self.navigationItem.rightBarButtonItem = barItem;
    [self makeTestMsg];
    /// 设置接受消息的代理
    [[LMConnectIMChater sharedManager] addReciveMessageDelegate:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.msgArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMMessageLayout *msgLayout = [self.msgArray objectAtIndex:indexPath.row];
    return msgLayout.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMMessageLayout *msgLayout = [self.msgArray objectAtIndex:indexPath.row];
    NSString *identifier = [LMMessageHelper cellIdentifierWithMsgType:msgLayout.chatMessage.msgType];
    LMMessageBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.msgLayout = msgLayout;
    cell.delegate = self;
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
}

#pragma mark -cell点击事件处理
- (void)imageDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout {
    NSLog(@"图片点击");
    self.assetArray = [NSMutableArray array];
    
    PhotoMessage *phoMsg = (PhotoMessage *)msgLayout.chatMessage.msgContent;
    // Add video with poster photo
    MWPhoto *photo = [[MWPhoto alloc] initWithImage:[[YYImageCache sharedCache] getImageForKey:phoMsg.thum.sha1String]];
    [self.assetArray addObject:photo];
    
    // Create browser (must be done each time photo browser is
    // displayed. Photo browser objects cannot be re-used)
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    browser.autoPlayOnAppear = NO; // Auto-play first video
    
    // Customise selection images to change colours if required
    browser.customImageSelectedIconName = @"ImageSelected.png";
    browser.customImageSelectedSmallIconName = @"ImageSelectedSmall.png";
    
    // Optionally set the current visible photo before displaying
    [browser setCurrentPhotoIndex:1];
    
    // Present
    [self.navigationController pushViewController:browser animated:YES];
    
    // Manipulate
    [browser showNextPhotoAnimated:YES];
    [browser showPreviousPhotoAnimated:YES];
    [browser setCurrentPhotoIndex:10];
}

- (void)videoDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout {
    NSLog(@"播放视频 %@",msgLayout.videoURL.absoluteString);
    AVPlayer *player = [AVPlayer playerWithURL:msgLayout.videoURL];
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = player;
    [self presentViewController:playerViewController animated:YES completion:nil];
    [playerViewController.player play];
}

- (void)headAvatarDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout {
    NSLog(@"头像点击 %@",msgLayout.sender.username);
}

- (void)highlightTextDidTap:(UITableViewCell *)cell msgLayout:(LMMessageLayout *)msgLayout userInfo:(NSDictionary *)userInfo {
    NSLog(@"chatMessage.msgContent %@",msgLayout.chatMessage.msgContent);
    if ([userInfo objectForKey:MSGUpdateAppName]) {
        NSLog(@"升级app");
    } else if ([userInfo objectForKey:MSGLinkURLName]) {
        NSLog(@"url %@",[userInfo objectForKey:MSGLinkURLName]);
    } else if ([userInfo objectForKey:MSGLinkEmailName]) {
        NSLog(@"email %@",[userInfo objectForKey:MSGLinkEmailName]);
    } else if ([userInfo objectForKey:MSGLinkPhoneName]) {
        NSLog(@"phone %@",[userInfo objectForKey:MSGLinkPhoneName]);
    } else if ([userInfo objectForKey:MSGDetailName]) {
        NSLog(@"detail hashid %@",[userInfo objectForKey:MSGDetailName]);
    } else if ([userInfo objectForKey:MSGNotRelationAddName]) {
        NSLog(@"add friend");
    }
}

- (void)showHidenSenderName:(UISwitch *)swit {
    for (LMMessageLayout *msgLayout in self.msgArray) {
        if (!msgLayout.chatMessage.sendFromSelf &&
            msgLayout.chatMessage.msgType != LMMessageTypeTip &&
            msgLayout.chatMessage.msgType != LMMessageTypeTime) {
            if (swit.isOn) {
                LMUserInfo *userInfo = [LMUserInfo new];
                userInfo.username = self.chatUser.username;
                msgLayout.sender = userInfo;
            } else {
                msgLayout.sender = nil;
            }
            [msgLayout layout];
        }
    }
    
    [self.msgTableView reloadData];
}


- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.assetArray.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    return [self.assetArray objectAtIndex:index];
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    return [self.assetArray objectAtIndex:index];
}

- (void)makeTestMsg {
    NSArray *msgarr = [[[LMConnectIMChater sharedManager] messageDBManager] fetchMessageFromTime:nil limit:0];
    for (LMMessage *msg in msgarr) {
        LMMessageLayout *msgLayout = [[LMMessageLayout alloc] initWithMessage:msg sender:nil];
        if (msg.sendFromSelf) {
            msgLayout.sendAvatar = self.loginUser.avatar;
        } else {
            msgLayout.sendAvatar = self.chatUser.avatar;
        }
        msgLayout.ECDHKey = [LMEncryptKit getECDHkeyWithPrivkey:[LMConnectIMChater sharedManager].chatSessionManager.connectPrikey publicKey:self.chatUser.pubKey];
        if (msg.createTime.timeIntervalSince1970 - self.lastMsgTime > 10) {
            self.lastMsgTime = msg.createTime.timeIntervalSince1970;
            [self insertTime];
        }
        [self.msgArray addObject:msgLayout];
    }
    [self.msgTableView reloadData];
    /// 滚动列表
    [self.msgTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.msgArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}


- (void)insertTime {
    LMMessage *time = [LMMessage new];
    time.msgOwer = self.chatUser.uid;
    time.msgId = [LMMessageTool generateMessageId];
    time.createTime = [NSDate date];
    TimeMessage *msgTime = [TimeMessage new];
    msgTime.time = [[NSDate date] messageTime];
    time.msgContent = msgTime;
    time.msgType = LMMessageTypeTime;
    LMMessageLayout *TimeMsgLayout = [[LMMessageLayout alloc] initWithMessage:time sender:nil];
    [self.msgArray addObject:TimeMsgLayout];
}


@end
