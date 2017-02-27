//
//  DSBasePlayerControlView.m
//  DemoTest
//
//  Created by Apple on 16/3/7.
//  Copyright © 2016年 xiuxiukeji. All rights reserved.
//

#import "DSBasePlayerControlView.h"

@interface DSBasePlayerControlView()
@property (nonatomic, assign) CGFloat leadingOfSeekSlider;
@end


@implementation DSBasePlayerControlView
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(routeChanged:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:[AVAudioSession sharedInstance]];
        // 监听程序进入非活跃状态
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(routeChanged:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:[AVAudioSession sharedInstance]];
        // 监听程序进入非活跃状态
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - 控件视图
/// 控件类型
- (void) configControlType:(DSPlayControlType) playControlType {
    self.playControlType = playControlType;
    switch (playControlType) {
        case DSPlayControlType4:
            [self configCenterPlayButtonAndProgessView];
            break;
        case DSPlayControlType5:
            [self configCenterPlayButtonType5];
            break;
        default:
            break;
    }
}
/// 没有滑动控制器
- (void) configNoSilderTypeView {
    // 播放按钮
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage imageNamed:@"ds_all_icon_play"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(onButtonStopAndPlay:) forControlEvents:UIControlEventTouchUpInside];
    _playButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    [self addSubview:_playButton];
    [_playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    // 进度
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.height - 2, SCREEN_WIDTH, 3)];
    _progressView.progress = 0.0;
    _progressView.progressTintColor = ColorOfHex(0xff7373);
    _progressView.trackTintColor = ColorOfHex(0xb1b1b1);
    _progressView.hidden = NO;
    [self addSubview:_progressView];
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.leading.bottom.equalTo(self);
        make.height.mas_equalTo(3);
    }];
}



/// 中间按钮播放时有进度(type 4)
- (void) configCenterPlayButtonAndProgessView {
    if (_bottomView) {
        return;
    }
    [self configCenterPlayButtonAndBottomBarWithType:DSPlayControlType4];
    
    _currentPlayTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    _currentPlayTimeLabel.text = @"00:00";
    _currentPlayTimeLabel.textColor = [UIColor whiteColor];
    _currentPlayTimeLabel.font = [UIFont systemFontOfSize:12.0];
    _currentPlayTimeLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_currentPlayTimeLabel];
    [_currentPlayTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(_bottomView);
        make.width.mas_equalTo(60);
    }];
    
    _totalPlayTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60, 0, 60, 30)];
    _totalPlayTimeLabel.text = @"00:00";
    _totalPlayTimeLabel.textColor = [UIColor whiteColor];
    _totalPlayTimeLabel.font = [UIFont systemFontOfSize:12.0];
    _totalPlayTimeLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_totalPlayTimeLabel];
    [_totalPlayTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(_bottomView);
        if (self.showFullScreenBtn) {
            make.trailing.equalTo(_bottomView).offset(- 30);
        }
        else {
            make.trailing.equalTo(_bottomView);
        }
        make.width.mas_equalTo(60);
    }];
    
    if (self.showFullScreenBtn) {
        self.fullScreenButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
        self.fullScreenButton.exclusiveTouch = YES;
        [self.fullScreenButton setImage:[UIImage imageNamed:@"ds_detail_fullscreen_open"] forState:UIControlStateNormal];
        [self.fullScreenButton setImage:[UIImage imageNamed:@"ds_detail_fullscreen_close"] forState:UIControlStateSelected];
        [self.fullScreenButton addTarget:self action:@selector(onClickFullScreen:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:self.fullScreenButton];
        [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.trailing.equalTo(self.bottomView); make.width.mas_equalTo(40);
        }];
    }
}
/// 中间按钮播放时有进度(type 5)
- (void) configCenterPlayButtonType5 {
    if (_bottomView) {
        return;
    }
    [self configCenterPlayButtonAndBottomBarWithType:DSPlayControlType5];
    
    _seekSlider.minimumTrackTintColor = ColorOfHex(0xff785a);
    _seekSlider.maximumTrackTintColor = ColorOfHex(0x5c5c5c);
    _progressView.progressTintColor = ColorOfHex(0xff785a);
    _progressView.trackTintColor = ColorOfHex(0x5c5c5c);
    _bottomView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    _totalPlayTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60, 0, 60, 30)];
    _totalPlayTimeLabel.text = @"00:00/00:00";
    _totalPlayTimeLabel.textColor = [UIColor whiteColor];
    _totalPlayTimeLabel.font = [UIFont systemFontOfSize:10.0];
    _totalPlayTimeLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_totalPlayTimeLabel];
    [_totalPlayTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(_bottomView);
        make.width.mas_equalTo(70);
    }];
}
// 中间播放按钮 底部播放状态栏公用代码抽取
- (void) configCenterPlayButtonAndBottomBarWithType:(DSPlayControlType)controlType {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage imageNamed:@"ds_all_icon_play"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(onButtonStopAndPlay:) forControlEvents:UIControlEventTouchUpInside];
    _playButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    [self addSubview:_playButton];
    [_playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 30, SCREEN_WIDTH, 30)];
    _bottomView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [self addSubview:_bottomView];
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.leading.trailing.equalTo(self);
        make.height.mas_equalTo(30);
    }];
    
    CGFloat sliderLeadingConstant = 60;
    CGFloat sliderTrailingConstant = -60;
    if (controlType == DSPlayControlType5) {
        sliderLeadingConstant = 12;
        sliderTrailingConstant = -70;
    }
    if (self.showFullScreenBtn) {
        sliderTrailingConstant -= 30;
    }
    _seekSlider = [[UISlider alloc] initWithFrame:CGRectMake(60, 0, SCREEN_WIDTH - 120, 30)];
    [_seekSlider setThumbImage:[UIImage imageNamed:@"ds_circle"] forState:UIControlStateNormal];
    [_seekSlider setThumbImage:[UIImage imageNamed:@"ds_circle"] forState:UIControlStateHighlighted];
    _seekSlider.minimumTrackTintColor = ColorOfHexAndAlpha(0xFF785A, 1);
    _seekSlider.maximumTrackTintColor = ColorOfHexAndAlpha(0x2D2E32, 1.0);
    [_seekSlider addTarget:self action:@selector(onSliderValueDidChanged:) forControlEvents:UIControlEventValueChanged];
    [_seekSlider addTarget:self action:@selector(onSliderDoneAction:) forControlEvents:UIControlEventTouchUpInside];
    [_seekSlider addTarget:self action:@selector(onSliderDoneAction:) forControlEvents:UIControlEventTouchUpOutside];
    [_seekSlider addTarget:self action:@selector(onSliderValueStartChange:) forControlEvents:UIControlEventTouchDown];
    
    [_bottomView addSubview:_seekSlider];
    [_seekSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.leading.mas_equalTo(sliderLeadingConstant);
        make.trailing.mas_equalTo(sliderTrailingConstant);
        make.top.bottom.equalTo(_bottomView);
    }];
    self.leadingOfSeekSlider = sliderLeadingConstant;
    
    _bottomView.userInteractionEnabled = YES;
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.height - 2, SCREEN_WIDTH, 2)];
    _progressView.progress = 0.0;
    _progressView.progressTintColor = ColorOfHexAndAlpha(0xFF785A, 1.0);
    _progressView.trackTintColor = ColorOfHexAndAlpha(0x2D2E32, 1.0);
    _progressView.hidden = YES;
    [self addSubview:_progressView];
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.leading.bottom.equalTo(self);
        make.height.mas_equalTo(2);
    }];
}

- (void)setLeftView:(UIView *)leftView
{
    if (! _leftView && ! leftView) {
        return;
    }
    [self.leftView removeFromSuperview];
    if (! leftView) {
        self.leadingOfSeekSlider -= self.leftView.width;
        [_seekSlider mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.leadingOfSeekSlider);
        }];
        
        [_currentPlayTimeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(@(0));
        }];
        _leftView = nil;
    }
    else {
        self.leadingOfSeekSlider += leftView.width - self.leftView.width;
        [_seekSlider mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.leadingOfSeekSlider);
        }];
        
        [_currentPlayTimeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(leftView.width - self.leftView.width);
        }];
        [_bottomView addSubview:leftView];
        [leftView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.mas_equalTo(0); make.width.mas_equalTo(leftView.width);
        }];
        _leftView = leftView;
    }
}

#pragma mark - 事件处理需要重载
- (void) onButtonStopAndPlay:(UIButton *)sender {
    
}

- (void) onSliderDoneAction:(UISlider *)slider {

}

- (void) onSliderValueDidChanged:(UISlider *)slider {
    
}

- (void) onSliderValueStartChange:(UISlider *)slider {
    
}
- (void) onSliderPan:(UIPanGestureRecognizer *)g {

}

- (void)onClickFullScreen:(UIButton *)sender
{
    self.fullScreenButton.selected = ! self.fullScreenButton.selected;
}

#pragma mark - 视图处理 可重载
/// 更新控件根据播放状态
- (void) updatePlayControlView:(BOOL) isPlaying contolType:(DSPlayControlType) controlType {
    switch (controlType) {
        case DSPlayControlType4:
            [self updatePlayControlViewForType4:isPlaying];
            break;
        case DSPlayControlType5:
            [self updatePlayControlViewForType5:isPlaying];
            break;
        default:
            break;
    }
}
/// DSPlayControlType4 根据播放状态更新
- (void) updatePlayControlViewForType4:(BOOL) isPlaying {
    
}

/// DSPlayControlType5 根据播放状态更新
- (void) updatePlayControlViewForType5:(BOOL) isPlaying {
    
}


- (void) updateTimeShowView:(NSTimeInterval)currentTime {
    
}

#pragma mark - 操作处理可重写
- (void) stopPlay {
    
}
-(void) startPlay {

}
- (void) routeChanged:(NSNotification *)notify {
    DEBUG_NSLog(@"%@",notify.userInfo);
    int changeReasinKey = [[notify.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    if (changeReasinKey == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        async_main(^{
            [self stopPlay];
        });
    }
}
@end
