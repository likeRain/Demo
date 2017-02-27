//
//  DSLoaclPlayerControlView.m
//  DemoTest
//
//  Created by Apple on 16/3/7.
//  Copyright © 2016年 xiuxiukeji. All rights reserved.
//

#import "DSLoaclPlayerControlView.h"
#import "DSVideoPlayView.h"
#import "DSPlayerSubtitleShowView.h"

@interface DSLoaclPlayerControlView ()<DSVideoPlayViewDelegate>
@property (nonatomic, strong) DSVideoPlayView          *videoPlayView;
@property (nonatomic, strong) UIImageView              *thumbImageView;
@property (nonatomic, strong) DSPlayerSubtitleShowView *playSubtitleView;

@property (nonatomic, assign) BOOL                isSliderChanging;
@property (nonatomic, assign) BOOL                isPlayDoneSliderAction;
@end

@implementation DSLoaclPlayerControlView
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.thumbImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.thumbImageView];
        [self.thumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        _videoPlayView = [[DSVideoPlayView alloc] init];
        _videoPlayView.backgroundColor = [UIColor clearColor];
        _videoPlayView.delegate = self;
        [self addSubview:_videoPlayView];
        [_videoPlayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.thumbImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.thumbImageView];
        [self.thumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        _videoPlayView = [[DSVideoPlayView alloc] init];
        _videoPlayView.backgroundColor = [UIColor clearColor];
        _videoPlayView.delegate = self;
        [self addSubview:_videoPlayView];
        [_videoPlayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

// 外放处理
- (void) volumeOutSet {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    //Replace by ?
    if (![self isHeadphone]) {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
}
- (BOOL)isHeadphone {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    NSArray *outputs = route.outputs;
    for (AVAudioSessionPortDescription *output in outputs) {
        if ([AVAudioSessionPortHeadphones isEqualToString:output.portType] || [AVAudioSessionPortHeadsetMic isEqualToString:output.portType]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - 公开方法
/// 假如有字幕添加字幕
- (void) addPlaySubtitleViewifNeedWithShowSize:(CGSize)showSize withSrtUrl:(NSString *)srtUrl {
    [self removePlaySutitleView];
    _playSubtitleView = [[DSPlayerSubtitleShowView alloc] initWithSrtPath:srtUrl withShowSize:showSize];
    [self insertSubview:_playSubtitleView belowSubview:self.bottomView];
}
/// 删除字幕视图
- (void) removePlaySutitleView {
    if (_playSubtitleView) {
        [_playSubtitleView removeFromSuperview];
        _playSubtitleView = nil;
    }
}
/// 更新字幕字幕显示大小
- (void) updateSubtitleViewShowSize:(CGSize)showSize {
    [_playSubtitleView updateViewShowScaleWithShowSize:showSize];
}
/// 播放本地视频
- (void) configControlWithLocalUrl:(NSString *)playUrl andControlPlayerType:(DSPlayControlType)playerType {
    [self configControlWithLocalUrl:playUrl andBackgroundAudioUrl:@"" andControlPlayerType:playerType];
}
/// 和背景音一起播放
- (void) configControlWithLocalUrl:(NSString *)playUrl andBackgroundAudioUrl:(NSString *)bkgAudioUrl andControlPlayerType:(DSPlayControlType)playerType {
    self.playControlType = playerType;
    self.seekSlider.value = 0.0;
    if (playUrl.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:playUrl]) {
        [_videoPlayView configAVPlayer:playUrl];
        [_videoPlayView addBackgroundAudioWithUrl:bkgAudioUrl];
    }
    [self configControlType:playerType];
    [_videoPlayView seek:0 completionHandler:nil];
    [self updateTimeShowView:[_videoPlayView currentPlaySeconds]];
}
/// 播放视频原声
- (void) configControlPlayOrgWithLocalUrl:(NSString *)playUrl withControlPlayerType:(DSPlayControlType)playerType {
    self.playControlType = playerType;
    self.seekSlider.value = 0.0;
    if (playUrl.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:playUrl]) {
        [_videoPlayView configAVPlayer:playUrl];
        [_videoPlayView addVideoOriginalAudio];
    }
    [self configControlType:playerType];
    [self updateTimeShowView:[_videoPlayView currentPlaySeconds]];
}
- (void) stopPlay {
    if (_videoPlayView.isPlaying) {
        [self onButtonStopAndPlay:nil];
    } else {
        [self updatePlayControlView:NO contolType:self.playControlType];
    }
}
-(void) startPlay {
    [self volumeOutSet];
    if (!_videoPlayView.isPlaying) {
        [self onButtonStopAndPlay:nil];
    } else {
        [self updatePlayControlView:YES contolType:self.playControlType];
    }
}
#pragma mark - 视图处理
- (void) updateTimeShowView:(NSTimeInterval)currentTime {
    NSTimeInterval totalTime = _videoPlayView.totalSeconds;
    switch (self.playControlType) {
        case DSPlayControlType4:
            self.currentPlayTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)[@(currentTime) integerFor001] / 60, (long)[@(currentTime) integerFor001] % 60];
            self.totalPlayTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)[@(totalTime) integerFor001] / 60, (long)[@(totalTime) integerFor001] % 60];
            break;
        case DSPlayControlType5:
            self.totalPlayTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld/%02ld:%02ld", (long)[@(currentTime) integerFor001] / 60, (long)[@(currentTime) integerFor001] % 60, (long)[@(totalTime) integerFor001] / 60, (long)[@(totalTime) integerFor001] % 60];
            break;
        default:
            break;
    }
}

/// DSPlayControlType4 根据播放状态更新
- (void) updatePlayControlViewForType4:(BOOL) isPlaying {
    if (_isSliderChanging) {
        return;
    }
    if (isPlaying) {
        [self.playButton setImage:nil forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor clearColor];
        [self performSelector:@selector(progressViewChangeAfterPlayingForType4andType5) withObject:nil afterDelay:4.0];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"ds_all_icon_play"] forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
        [self progressViewChangeAfterStopForType4andType5];
    }
    
}
/// DSPlayControlType5 根据播放状态更新
- (void) updatePlayControlViewForType5:(BOOL) isPlaying {
    [self updatePlayControlViewForType4:isPlaying];
}

/// 隐藏底部控件 显示进度条
- (void) progressViewChangeAfterPlayingForType4andType5 {
    if (_isSliderChanging) {
        return;
    }
    self.bottomView.hidden = YES;
    self.progressView.hidden = NO;
}

/// 隐藏底部控件 显示进度条
- (void) progressViewChangeAfterStopForType4andType5 {
    [DSLoaclPlayerControlView cancelPreviousPerformRequestsWithTarget:self selector:@selector(progressViewChangeAfterPlayingForType4andType5) object:nil];
    self.bottomView.hidden = NO;
    self.progressView.hidden = YES;
}

#pragma mark - 播放回调
- (void) videoPlayView:(DSVideoPlayView *)videoPlayView playCallBack:(long)playTime {
    NSTimeInterval totalSeconds = videoPlayView.totalSeconds;
    NSTimeInterval playSeconds = playTime / 1000.0;
    if (totalSeconds > 0) {
        CGFloat progressValue = playSeconds / totalSeconds;
        self.progressView.progress = progressValue;
        self.seekSlider.value = progressValue;
        [self updateTimeShowView:playSeconds];
    }
    [_playSubtitleView updateViewWithPlayTime:playTime];
}
// 播放完成回调
- (void) videoDonePlayVideoPlayView:(DSVideoPlayView *)videoPlayView {
    
}

/// 播放状态改变
- (void) videoPlayView:(DSVideoPlayView *)videoPlayView isPlaying:(BOOL) isPlaying {
    [self updatePlayControlView:isPlaying contolType:self.playControlType];
}

#pragma mark - 事件处理
- (void) onSliderValueStartChange:(UISlider *)slider {
    _isSliderChanging = YES;
    _isPlayDoneSliderAction = _videoPlayView.isPlaying;
    [_videoPlayView pause];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}


- (void) onSliderValueDidChanged:(UISlider *)slider {
    
    NSTimeInterval totalSeconds = _videoPlayView.totalSeconds;
    if (totalSeconds > 0) {
        NSTimeInterval seekSeconds = totalSeconds * slider.value;
        self.progressView.progress = slider.value;
        [self updateTimeShowView:seekSeconds];
    }
}

- (void) onSliderDoneAction:(UISlider *)slider {
    _isSliderChanging = NO;
    NSTimeInterval totalSeconds = _videoPlayView.totalSeconds;
    if (totalSeconds > 0) {
        NSTimeInterval seekSeconds = totalSeconds * slider.value;
        [_videoPlayView seek:seekSeconds * 1000 completionHandler:^(BOOL finished) {
            if (_isPlayDoneSliderAction) {
                _isPlayDoneSliderAction = NO;
                [_videoPlayView play];
            }
        }];
    }
}

- (void) onButtonStopAndPlay:(UIButton *)sender {
    _isSliderChanging = NO;
    if (_videoPlayView.totalSeconds < 0.01) {
        return;
    }
    if (_videoPlayView.isPlaying) {
        [_videoPlayView pause];
    } else {
        [_videoPlayView play];
    }
}

- (void) dealloc {
    [_videoPlayView destroyPlayback];
}

@end
