//
//  ViewController.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/7.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "ViewController.h"
#import "LMMessageViewController.h"
#import "LMConnectIMChater.h"
#import "LMMessageDBManager.h"
#import <YYKit/YYKit.h>

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *timeView;

@property (nonatomic ,strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    /// 配置
    [[LMConnectIMChater sharedManager].chatSessionManager configWithConnectUid:@"1234560" connectPubkey:@"0251688e11db0e836d751620c05bb13c5d0083fb28ea7c62ae70faa6e9139884f0" connectPrikey:@"L2KqiWPMJQWxCBmTTPWsHiLi6ujKgJRiizzzBatRiZ8C2Uh8ZNNT" connectServerPubkey:@"03d307e51af08983cc0c13bb11d3619758e7b0b8a374e610de3503fc4ebeedfe96"];
    [[LMConnectIMChater sharedManager] configMessageDBManager:[LMMessageDBManager new]];
    [[LMConnectIMChater sharedManager] startIMServer];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ID"];
    }
    cell.textLabel.text = @"聊天会话";
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LMMessageViewController *page = [[LMMessageViewController alloc] init];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
