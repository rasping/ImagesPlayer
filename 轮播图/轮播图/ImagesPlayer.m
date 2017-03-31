//
//  ImagesPlayer.m
//  轮播图
//
//  Created by siping ruan on 16/9/27.
//  Copyright © 2016年 Rasping. All rights reserved.
//

#import "ImagesPlayer.h"
#import <CommonCrypto/CommonCrypto.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define imageCount self.dataArray.count
#define W self.frame.size.width
#define H self.frame.size.height

@interface ImagesPlayer ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) UICollectionView *collectionView;
@property (weak, nonatomic)UICollectionViewFlowLayout *flow;
@property (strong, nonatomic) NSTimer *timer;
/**
 *  分页指示器
 */
@property (weak, nonatomic) UIPageControl *indicatorView;
/**
 *  数据源
 */
@property (strong, nonatomic) NSMutableArray *dataArray;
/**
 *  记录滚动前偏移量
 */
@property (assign, nonatomic) CGFloat previousOffsetX;
/**
 *  占位图
 */
@property (strong, nonatomic) UIImage *placeHolder;
/**
 *  点击回调
 */
@property (copy, nonatomic) void (^ block) (NSInteger);

@end

@implementation ImagesPlayer

#pragma mark - Setter/Getter

- (UIPageControl *)indicatorView
{
    if (!_indicatorView) {
        UIPageControl *page                = [[UIPageControl alloc] init];
        page.currentPageIndicatorTintColor = [UIColor whiteColor];
        page.pageIndicatorTintColor        = [UIColor grayColor];
        [self addSubview:page];
        _indicatorView = page;
    }
    return _indicatorView;
}

- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (void)setAutoScroll:(BOOL)autoScroll
{
    _autoScroll = autoScroll;
    if (_autoScroll == NO) {
        [self removeTimer];
    }
}

- (void)setHidePageControl:(BOOL)hidePageControl
{
    _hidePageControl          = hidePageControl;
    self.indicatorView.hidden = hidePageControl;
}

- (void)setScrollIntervalTime:(NSTimeInterval)scrollIntervalTime
{
    if (_scrollIntervalTime != scrollIntervalTime) {
        _scrollIntervalTime = scrollIntervalTime;
        [self removeTimer];
        [self addTimer];
    }
}

- (void)setIndicatorPattern:(id<ImagesPlayerIndictorPattern>)indicatorPattern
{
    _indicatorPattern = indicatorPattern;
    if (indicatorPattern) {
        [self.indicatorView removeFromSuperview];
        [self layoutIfNeeded];
        [self addSubview:[self.indicatorPattern indicatorViewInImagesPlayer:self]];
    }
}

#pragma mark - Initail

- (instancetype)init
{
    if (self = [super init]) {
        [self addOwnViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self addOwnViews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.flow.itemSize        = self.frame.size;
    self.collectionView.frame = self.bounds;
    
    self.indicatorView.frame  = CGRectMake(W * 0.5, H - 15.0, 0, 0);
}

#pragma mark - Private

//添加子视图
- (void)addOwnViews
{
    //初始值
    self.autoScroll         = YES;
    self.hidePageControl    = NO;
    
    //subViews
    [self addCollectionView];
    [self bringSubviewToFront:self.indicatorView];
}

static NSString * const reuseIdentifier = @"ImagesPlayerCell";
//添加collectionView
- (void)addCollectionView
{
    UICollectionViewFlowLayout *flow              = [[UICollectionViewFlowLayout alloc] init];
    flow.minimumLineSpacing                       = 0.0;
    flow.scrollDirection                          = UICollectionViewScrollDirectionHorizontal;
    self.flow                                     = flow;
    UICollectionView *collectionView              = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
    collectionView.delegate                       = self;
    collectionView.dataSource                     = self;
    collectionView.pagingEnabled                  = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.backgroundColor                = [UIColor clearColor];
    self.collectionView                           = collectionView;
    [self addSubview:collectionView];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

//检查添加的images数组中的元素
+ (void)checkElementOfImages:(NSArray *)images
{
    for (id obj in images) {
        if (![obj isKindOfClass:[NSString class]]) {
            NSException *e = [NSException exceptionWithName:@"PathVailed" reason:@"必须为图片名、图片本地路径或是图片地址" userInfo:nil];
            @throw e;
        }
    }
}

//添加定时器
- (void)addTimer
{
    if (!self.autoScroll) return;
    NSUInteger interval = self.scrollIntervalTime ? self.scrollIntervalTime : 2;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(nextImage) userInfo:nil repeats:YES];
}

- (void)nextImage
{
    if ((int)self.collectionView.contentOffset.x % (int)W == 0) {
        CGFloat offsetX = self.collectionView.contentOffset.x + W;
        [self.collectionView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
    }else {
        NSInteger count = round(self.collectionView.contentOffset.x / W);
        [self.collectionView setContentOffset:CGPointMake(count * W, 0) animated:NO];
    }
}

#pragma mark - Public

- (void)addLocalImages:(NSArray<NSString *> *)images
{
    [ImagesPlayer checkElementOfImages:images];
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:images];
    _images = [NSArray arrayWithArray:self.dataArray];
    
    //刷新pageControl
    self.indicatorView.numberOfPages = images.count;
    [self.indicatorView updateCurrentPageDisplay];
    
    //在Updates里执行完更新操作后再执行completion回调
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadData];
    } completion:^(BOOL finished) {
        //刷新完成让collectionView滚动到中间位置
        NSInteger center = ceilf([self.collectionView numberOfItemsInSection:0] * 0.5);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:center inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
        self.previousOffsetX = self.collectionView.contentOffset.x;
        
        //通知指示器的初始值
        if ([self.indicatorPattern respondsToSelector:@selector(imagesPlayer:didChangedIndex:count:)]) {
            [self.indicatorPattern imagesPlayer:self didChangedIndex:0 count:imageCount];
        }
        
        //开启定时器
        [self removeTimer];
        [self addTimer];
    }];
}

- (void)addNetWorkImages:(NSArray<NSString *> *)images placeholder:(UIImage *)placeholder
{
    [self addLocalImages:images];
    self.placeHolder = placeholder;
}

- (void)imageTapAction:(void (^)(NSInteger))block
{
    self.block = block;
}

- (void)removeTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (CGFloat)calculateCacheImagesMemory
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *fileDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"imagesCache"];
    NSDictionary *fileAttr = [manager attributesOfItemAtPath:fileDir error:nil];
    NSUInteger filesSize = [fileAttr fileSize];
    return filesSize / (1000 * 1000);
}

- (void)removeCacheMemory
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *fileDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"imagesCache"];
    for (NSString *subPath in [manager subpathsOfDirectoryAtPath:fileDir error:nil]) {
        [manager removeItemAtPath:subPath error:nil];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return imageCount * 1000;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell       = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    UIImageView *imageView           = [[UIImageView alloc] init];
    imageView.userInteractionEnabled = YES;
    NSString *imageName              = self.dataArray[indexPath.item % imageCount];
    UIImage *image                   = [UIImage imageNamed:imageName];
    if (image) {//本地图片
        imageView.image              = image;
    }else {//网络图片
        [imageView setImageWithURL:imageName placeholderImage:self.placeHolder];
    }
    cell.backgroundView              = imageView;
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //当cell不能再滑动时，让collectionView再次滚动到中间位置
    NSInteger number = [collectionView numberOfItemsInSection:0];
    if (number == indexPath.item + 1 || 0 == indexPath.item) {
        NSInteger adjust = self.previousOffsetX - collectionView.contentOffset.x;
        adjust = adjust > 0 ? 1 : -2;
        self.previousOffsetX = collectionView.contentOffset.x;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ceilf(number * 0.5) + adjust inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.block) {
        self.block(indexPath.item % imageCount);
    }
    if ([self.delegate respondsToSelector:@selector(imagesPlayer:didSelectImageAtIndex:)]) {
        [self.delegate imagesPlayer:self didSelectImageAtIndex:(indexPath.item % imageCount)];
    }
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    NSInteger page = (NSInteger)(scrollView.contentOffset.x / W )% imageCount;
    
    self.indicatorView.currentPage = page;
    //通知代理更新自定义分页指示器
    if ([self.indicatorPattern respondsToSelector:@selector(imagesPlayer:didChangedIndex:count:)]) {
        [self.indicatorPattern imagesPlayer:self didChangedIndex:page count:imageCount];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = (NSInteger)(scrollView.contentOffset.x / W )% imageCount;
    
    self.indicatorView.currentPage = page;
    //通知代理更新自定义分页指示器
    if ([self.indicatorPattern respondsToSelector:@selector(imagesPlayer:didChangedIndex:count:)]) {
        [self.indicatorPattern imagesPlayer:self didChangedIndex:page count:imageCount];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self removeTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self addTimer];
}

@end

@implementation UIImageView (WebCache)

- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder
{
    NSString *fileDir  = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"imagesCache"];
    NSFileManager *fm  = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *fileName = [fileDir stringByAppendingPathComponent:[self md5:url]];//MD5加密图片名全路径
    UIImage *image     = [UIImage imageWithContentsOfFile:fileName];
    if (image) {
        self.image = image;
    }else {
        self.image = placeholder;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *path = [NSURL URLWithString:url];
            NSData *data = [NSData dataWithContentsOfURL:path];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = [UIImage imageWithData:data];
            });
            [data writeToFile:fileName atomically:YES];
        });
    }
}

//MD5加密
- (NSString *)md5:(NSString *)string
{
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (int)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end
