//
//  DSBasePlayerControlView.h
//  DemoTest
//
//  Created by Apple on 16/3/7.
//  Copyright © 2016年 xiuxiukeji. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum:NSUInteger {
    //    DSPlayCenterPlayButton,
    //    DSPlayBottomPlayAlphaBar,
    //    DSPlayBottomPlayBar,
    DSPlayControlType4,// 中间按钮播放时有进度， 时间双侧显示
    DSPlayControlType5,// 中间按钮播放时有进度， 时间右侧显示
    DSPlayControlNoSliderType// 没有滑动进度
} DSPlayControlType;


@interface DSBasePlayerControlView : UIView
@property (nonatomic, strong) UILabel             *currentPlayTimeLabel;
@property (nonatomic, strong) UILabel             *totalPlayTimeLabel;
@property (nonatomic, strong) UIButton            *playButton;
@property (nonatomic, strong) UISlider            *seekSlider;
@property (nonatomic, strong) UIProgressView      *progressView;
@property (nonatomic, strong) UIView              *bottomView;

@property (nonatomic, strong) UIButton            *fullScreenButton;

@property (nonatomic, assign) DSPlayControlType playControlType;

@property (nonatomic, assign) BOOL showFullScreenBtn;
@property (nonatomic, strong) UIView *leftView;

#pragma mark - 控件
/// 没有滑动控制器
- (void) configNoSilderTypeView;
/// 中间按钮播放时有进度(type 4)
- (void) configCenterPlayButtonAndProgessView;
// 中间按钮播放时有进度(type 5)
- (void) configCenterPlayButtonType5;
#pragma mark - 事件处理需要重载
- (void) onButtonStopAndPlay:(UIButton *)sender;
- (void) onSliderDoneAction:(UISlider *)slider;
- (void) onSliderValueDidChanged:(UISlider *)slider;
- (void) onSliderValueStartChange:(UISlider *)slider;
- (void) onClickFullScreen:(UIButton *)sender;

#pragma mark - 视图处理可重载
- (void) updateTimeShowView:(NSTimeInterval)currentTime;
/// 更新控件根据播放状态
- (void) updatePlayControlView:(BOOL) isPlaying contolType:(DSPlayControlType) controlType;
/// DSPlayControlType4 根据播放状态更新
- (void) updatePlayControlViewForType4:(BOOL) isPlaying;
/// 控件类型
- (void) configControlType:(DSPlayControlType) playControlType;

#pragma mark - 操作处理可重写
- (void) stopPlay;
-(void) startPlay;
@end
