//
//  ImagesPlayer.h
//  轮播图
//
//  Created by siping ruan on 16/9/27.
//  Copyright © 2016年 Rasping. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImagesPlayerDelegae, ImagesPlayerIndictorPattern;

@interface ImagesPlayer : UIView

/**
 *  是否自动滚动 默认YES
 */
@property (nonatomic, assign) BOOL autoScroll;
/**
 *  滚动间隔时间 默认2秒
 */
@property (nonatomic, assign) NSTimeInterval scrollIntervalTime;
/**
 *  是否隐藏分页指示器 默认NO
 */
@property (nonatomic, assign) BOOL hidePageControl;
@property (weak, nonatomic) id<ImagesPlayerDelegae> delegate;
@property (weak, nonatomic) id<ImagesPlayerIndictorPattern> indicatorPattern;
/**
 *  当前展示的图片数组
 */
@property (strong, nonatomic, readonly) NSArray *images;
/**
 *  添加本地图片数组
 */
- (void)addLocalImages:(NSArray<NSString *> *)images;
/**
 *  添加网络图片数组
 */
- (void)addNetWorkImages:(NSArray <NSString *> *)images placeholder:(UIImage *)placeholder;
/**
 *  点击事件回调
 */
- (void)imageTapAction:(void (^) (NSInteger index))block;
/**
 *  移除定时器
 */
- (void)removeTimer;
/**
 *  计算缓存图片总大小（MB）
 */
- (CGFloat)calculateCacheImagesMemory;
/**
 *  清除图片缓存
 */
- (void)removeCacheMemory;

@end

/**
 *  代理
 */
@protocol ImagesPlayerDelegae <NSObject>

@optional

/**
 *  图片点击回调
 */
- (void)imagesPlayer:(ImagesPlayer *)player didSelectImageAtIndex:(NSInteger)index;

@end

/**
 *  指示器样式
 */
@protocol ImagesPlayerIndictorPattern <NSObject, UITableViewDelegate>

@required
/**
 *  设置分页指示器的样式
 */
- (UIView *)indicatorViewInImagesPlayer:(ImagesPlayer *)imagesPlayer;

@optional

/**
 *  图片交换完成时调用
 */
- (void)imagesPlayer:(ImagesPlayer *)imagesPlayer didChangedIndex:(NSInteger)index count:(NSInteger)count;

@end

@interface UIImageView (WebCache)

- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder;

@end