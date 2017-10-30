//
//  LMImageVideoBorwser.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/11.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMImageVideoBorwser.h"


@interface LMAssetModel : NSObject

@property (nonatomic ,assign) BOOL isVideo;
@property (nonatomic ,copy) NSString *thumUrl;
@property (nonatomic ,copy) NSString *originUrl;
@property (nonatomic ,strong) NSURL *videoLocalUrl;

@end

@implementation LMAssetModel

@end

@interface LMImageVideoBorwser ()

@property (nonatomic ,strong) NSMutableArray *assetArray;

@end

@implementation LMImageVideoBorwser


- (void)addImageThumUrl:(NSString *)url originUrl:(NSString *)originUrl {
    LMAssetModel *asset = [LMAssetModel new];
    asset.thumUrl = url;
    asset.originUrl = originUrl;
    [self.assetArray addObject:asset];
}

- (void)addVideoCoverUrl:(NSString *)coverUrl videoUrl:(NSString *)videoUrl videoLocalUrl:(NSURL *)videoLocalUrl {
    LMAssetModel *asset = [LMAssetModel new];
    asset.thumUrl = coverUrl;
    asset.originUrl = videoUrl;
    asset.videoLocalUrl = videoLocalUrl;
    [self.assetArray addObject:asset];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.assetArray = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
