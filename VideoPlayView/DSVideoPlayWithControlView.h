//
//  DSVideoPlayWithControlView.h
//  DemoTest
//
//  Created by zhoujianguang on 15/10/10.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import "DSVideoPlayer.h"

@class DSVideoPlayWithControlView;
@protocol DSVideoPlayWithControlViewDelegate <NSObject>

@optional
- (void)videoWillPlay:(DSVideoPlayWithControlView *)player;
- (void)videoWillStop:(DSVideoPlayWithControlView *)player;

@end

/**
 默认是播放原声的播放器，带有播放按钮和可拖动的底部进度条以及右下角的时间显示
 */
@interface DSVideoPlayWithControlView : DSVideoPlayer
@property (weak, nonatomic) id<DSVideoPlayWithControlViewDelegate> controlDelegate;

@property (readonly, weak, nonatomic) UISlider *playSlider;
@property (readonly, weak, nonatomic) UILabel *timeLabel;
@property (nonatomic, readonly) TimeRange limitPlayRange;
///设置限制播放的时间范围
- (void)setLimitPlayRange:(TimeRange)limitPlayRange;
@end
