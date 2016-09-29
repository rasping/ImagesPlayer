//
//  ViewController.m
//  轮播图
//
//  Created by siping ruan on 16/9/27.
//  Copyright © 2016年 Rasping. All rights reserved.
//

#import "ViewController.h"
#import "ImagesPlayer.h"

@interface ViewController ()<ImagesPlayerIndictorPattern, ImagesPlayerDelegae>

@property (weak, nonatomic) IBOutlet ImagesPlayer *localImagesView;
@property (weak, nonatomic) IBOutlet ImagesPlayer *networkImagesView;
@property (weak, nonatomic) UILabel *lable;

@end

@implementation ViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [self.networkImagesView removeTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *images = [NSMutableArray array];
    for (int index = 1; index < 6; index++) {
        NSString *imageName = [NSString stringWithFormat:@"%d_launch", index];
        [images addObject:imageName];
    }
    [self.localImagesView addLocalImages:images];
    self.localImagesView.autoScroll = NO;
    
    NSArray *netImages = @[@"http://www.ld12.com/upimg358/allimg/c151129/144WW1420B60-401445_lit.jpg",
                           @"http://img4.duitang.com/uploads/item/201508/11/20150811220329_XyZAv.png",
                           @"http://tx.haiqq.com/uploads/allimg/150326/160R95612-10.jpg",
                           @"http://img5q.duitang.com/uploads/item/201507/22/20150722145119_hJnyP.jpeg",
                           @"http://imgsrc.baidu.com/forum/w=580/sign=dc0e6c8c8101a18bf0eb1247ae2e0761/1cb3c90735fae6cd2c5341c109b30f2440a70fc7.jpg",];
    [self.networkImagesView addNetWorkImages:netImages placeholder:[UIImage imageNamed:@"1_launch"]];
    self.networkImagesView.delegate = self;
    self.networkImagesView.indicatorPattern = self;
}

#pragma mark = ImagesPlayerIndictorPattern

- (UIView *)indicatorViewInImagesPlayer:(ImagesPlayer *)imagesPlayer
{
    CGFloat margin          = 5.0;
    UIView *view            = [[UIView alloc] init];
    CGFloat w               = 50;
    CGFloat h               = 20;
    CGFloat x               = CGRectGetWidth(imagesPlayer.frame) - w - margin;
    CGFloat y               = CGRectGetHeight(imagesPlayer.frame) - h - margin;
    view.frame              = CGRectMake(x, y, w, h);
    view.backgroundColor    = [UIColor blackColor];
    view.alpha              = 0.5;
    view.clipsToBounds      = YES;
    view.layer.cornerRadius = 5.0;
    UILabel *lable          = [[UILabel alloc] initWithFrame:view.bounds];
    lable.textAlignment     = NSTextAlignmentCenter;
    lable.textColor         = [UIColor whiteColor];
    self.lable              = lable;
    [view addSubview:lable];
    return view;
}

- (void)imagesPlayer:(ImagesPlayer *)imagesPlayer didChangedIndex:(NSInteger)index count:(NSInteger)count
{
    self.lable.text = [NSString stringWithFormat:@"%ld/%ld", index, count];
}

#pragma mark - ImagesPlayerDelegae

- (void)imagesPlayer:(ImagesPlayer *)player didSelectImageAtIndex:(NSInteger)index
{
    NSLog(@"点击了：%ld", index);
}

@end
