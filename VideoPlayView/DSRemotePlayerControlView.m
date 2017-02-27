//
//  DSRemotePlayerControlView.m
//  DemoTest
//
//  Created by Apple on 15/12/28.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import "DSRemotePlayerControlView.h"
#import "DSRemoteVideoPlayer.h"
#import "DSRightIndicatorAndLeftTextView.h"
#import "DSDownloadMgr.h"
#import "DSPlayerSubtitleShowView.h"

@interface DSRemotePlayerControlView ()<DSRemoteVideoPlayerDelegate, DSDownloadMgrDelegate>
@property (nonatomic, strong) DSRemoteVideoPlayer *remoteVideoPlayer;
@property (nonatomic, strong) UIImageView         *thumbImageView;
@property (nonatomic, strong) UIButton            *fullViewButton;// 覆盖视频按钮
@property (nonatomic, strong) UILabel             *errorLabel;
@property (strong, nonatomic) DSRightIndicatorAndLeftTextView *loadingAcitvityIndicator;

@property (nonatomic, strong) DSPlayerSubtitleShowView *playSubtitleView;

@property (assign, nonatomic) BOOL isAutoStartPlayAfterReady;
@property (assign, nonatomic) BOOL isLoadingVideo;

@property (assign, nonatomic) BOOL isSliderChanging;
@property (assign, nonatomic) BOOL isPlayDoneSliderAction;
// -- 播放 逻辑参数--
@property (assign, nonatomic) BOOL  hasConfigPlayUrl;
@property (nonatomic, strong) NSString *playUrl;
@end

@implementation DSRemotePlayerControlView
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self defaultInit];
    }
    return self;
}
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self defaultInit];
    }
    return self;
}

- (void) defaultInit {
    self.backgroundColor = [UIColor blackColor];
    self.thumbImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:self.thumbImageView];
    [self.thumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    _remoteVideoPlayer = [[DSRemoteVideoPlayer alloc] init];
    _remoteVideoPlayer.backgroundColor = [UIColor clearColor];
    _remoteVideoPlayer.delegate = self;
    [self addSubview:_remoteVideoPlayer];
    [_remoteVideoPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    _fullViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _fullViewButton.frame = self.bounds;
    [_fullViewButton addTarget:self action:@selector(onButtonClickFullView:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_fullViewButton];
    [_fullViewButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
}


- (void) dealloc {
    [self removeObserver:self forKeyPath:@"bounds"];
    [_remoteVideoPlayer destroyPlayback];
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
#pragma mark - 观察回调
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        [self updateSubtitleViewWithShowVideoSize:self.bounds.size];
    }
}

#pragma mark - 下载回调
/// 进度回调
- (void) downloadProgress:(int)progress downloadType:(DSDownloadTypeEnum)downloadType {
    
}
///下载成功回调
- (void) didFinishDownload:(DSDownloadTypeEnum)downloadType cachePath:(NSString *)cachePath {
    CGSize showVideoSize = self.bounds.size;
    [self addSubtitleWithSrtFilePath:cachePath withVideoShowSize:showVideoSize];
}
///下载失败回调
- (void) didFailedDownload:(DSDownloadTypeEnum)downloadType {
    
}
#pragma mark - 公开方法
/// 添加播放字幕
- (void) addSubtitleWithSrtFilePath:(NSString *)filePath withVideoShowSize:(CGSize)showSize {
    if (_playSubtitleView) {
        [_playSubtitleView removeFromSuperview];
        _playSubtitleView = nil;
    }
    self.playSubtitleView = [[DSPlayerSubtitleShowView alloc] initWithSrtPath:filePath withShowSize:showSize];
    [self insertSubview:_playSubtitleView aboveSubview:_remoteVideoPlayer];
}
/// 添加外挂字幕，通过网络连接
- (void) showSubtitleWithSrtUrl:(NSString *)srtUrl {
    [[DSDownloadMgr shareMgr] downloadDubbedWorkSrtWithDownloadURL:srtUrl delegate:self];
}

/// 更新字幕播放视频显示尺寸
- (void) updateSubtitleViewWithShowVideoSize:(CGSize)showSize {
    if (_playSubtitleView) {
        [_playSubtitleView updateViewShowScaleWithShowSize:showSize];
    }
}

/// 控件类型
- (void) configControlType:(DSPlayControlType) playControlType thumbImageUrl:(NSString *)thumbImageUrl {
    [_thumbImageView sd_setImageWithURL:[NSURL URLWithString:thumbImageUrl] placeholderImage:[UIImage imageNamed:@"ds_dubbing_background-1"]];
    self.playControlType = playControlType;
    switch (playControlType) {
        case DSPlayControlType4:
            [self configCenterPlayButtonAndProgessView];
            break;
        case DSPlayControlType5:
            [self configCenterPlayButtonType5];
            break;
        case DSPlayControlNoSliderType:
            [self configNoSilderTypeView];
            break;
            break;
        default:
            break;
    }
}
/// 配置播放链接
- (void) configPlayerWithPlayUrl:(NSString *)playUrl isStartPlay:(BOOL)isStartPlay {
    [self configViewToInitState];
    if (playUrl.length > 0) {
        if (isStartPlay) {
            _playUrl = playUrl;
            self.isLoadingVideo = YES;
            [self updatePlayControlView:YES contolType:self.playControlType];
            [self.loadingAcitvityIndicator startAnimation];
             [_remoteVideoPlayer configPlayer:playUrl];
            _isAutoStartPlayAfterReady = YES;
            _hasConfigPlayUrl = YES;
        } else {
            _hasConfigPlayUrl = NO;
            _playUrl = playUrl;
        }
    }
}
/// 开始播放 play
- (void) startPlay {
    [self volumeOutSet];
    if (_remoteVideoPlayer.isPlaying == NO && !_isLoadingVideo) {
        [self onButtonStopAndPlay:nil];
    } else {
        [self updatePlayControlView:YES contolType:self.playControlType];
    }
}
- (void) stopPlay {
    if (_remoteVideoPlayer.isPlaying || _isLoadingVideo) {
        [self onButtonStopAndPlay:nil];
    } else {
        [self updatePlayControlView:NO contolType:self.playControlType];
    }
}


#pragma mark - 控件视图
/// 中间按钮播放时有进度(type 4)

#pragma mark - 视图处理
- (void) updateTimeShowView:(NSTimeInterval)currentTime {
    NSTimeInterval totalTime = _remoteVideoPlayer.totalSeconds;
    switch (self.playControlType) {
        case DSPlayControlType4:
            self.currentPlayTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)[@(currentTime) integerFor001] / 60, (long)[@(currentTime) integerFor001] % 60];
            self.totalPlayTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)[@(totalTime) integerFor001] / 60, (long)[@(totalTime) integerFor001] % 60];
            break;
        case DSPlayControlType5:
            self.totalPlayTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld/%02ld:%02ld", (long)[@(currentTime) integerFor001] / 60, (long)[@(currentTime) integerFor001] % 60, (long)[@(totalTime) integerFor001] / 60, (long)[@(totalTime) integerFor001] % 60];
            break;
        case DSPlayControlNoSliderType:
            
            break;
        default:
            break;
    }

}

/// 更新控件根据播放状态
- (void) updatePlayControlView:(BOOL) isPlaying contolType:(DSPlayControlType) controlType {
    switch (controlType) {
        case DSPlayControlType4:
            [self updatePlayControlViewForType4:isPlaying];
            break;
        case DSPlayControlType5:
            [self updatePlayControlViewForType5:isPlaying];
            break;
        case DSPlayControlNoSliderType:
            [self updateNoSliderControlWithPlaying:isPlaying];
            break;
        default:
            break;
    }
}
/// 没有改变播放进度
- (void) updateNoSliderControlWithPlaying:(BOOL) isPlaying {
    if (isPlaying || _isLoadingVideo) {
        //[_playButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [self.playButton setImage:nil forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor clearColor];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"ds_all_icon_play"] forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    }
}

/// DSPlayControlType4 根据播放状态更新
- (void) updatePlayControlViewForType4:(BOOL) isPlaying {
    if (_isSliderChanging) {
        return;
    }
    if (isPlaying || _isLoadingVideo) {
        //[_playButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [self.playButton setImage:nil forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor clearColor];
        [self performSelector:@selector(progressViewChangeAfterPlayingForType4) withObject:nil afterDelay:4.0];
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
- (void) progressViewChangeAfterPlayingForType4 {
    if (_isSliderChanging) {
        return;
    }
    self.bottomView.hidden = YES;
    self.progressView.hidden = NO;
}

/// 隐藏底部控件 显示进度条
- (void) progressViewChangeAfterStopForType4andType5 {
    [DSRemotePlayerControlView cancelPreviousPerformRequestsWithTarget:self selector:@selector(progressViewChangeAfterPlayingForType4) object:nil];
    self.bottomView.hidden = NO;
    self.progressView.hidden = YES;
}
/// 显示错误信息
- (void) showErrorMsg:(NSString *)msg {
    [self addSubview:self.errorLabel];
    if (msg.length > 0) {
        _errorLabel.text = msg;
    }
    [_errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    self.errorLabel.alpha = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            _errorLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            _errorLabel.alpha = 0.0;
            [_errorLabel removeFromSuperview];
        }];
    });
}

- (void) configViewToInitState {
    [_remoteVideoPlayer releasePlayer];
    _remoteVideoPlayer.backgroundColor = [UIColor clearColor];
    self.progressView.progress = 0.0;
    self.seekSlider.value = 0.0;
    [self updateTimeShowView:0.0];
    [self updatePlayControlView:NO contolType:self.playControlType];
    if (_loadingAcitvityIndicator) {
        [_loadingAcitvityIndicator stopAnimation];
    }
}
#pragma mark - 回调
- (void) remoteVideoPlayerDonePlay:(DSRemoteVideoPlayer *)remoteVideoPlayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControlViewDoneVideoPlay:)]) {
        [self.delegate playerControlViewDoneVideoPlay:self];
    }
}

- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer playTime:(NSTimeInterval)playTime {
    NSTimeInterval totalSeconds = remoteVideoPlayer.totalSeconds;
    if (totalSeconds > 0) {
        CGFloat progressValue = playTime / totalSeconds;
        self.progressView.progress = progressValue;
        self.seekSlider.value = progressValue;
        [self updateTimeShowView:playTime];
        [_playSubtitleView updateViewWithPlayTime:(long)(playTime * 1000)];
    }
    if ([self.delegate respondsToSelector:@selector(remoteVideoPlayer:playTime:)]) {
        [self.delegate remoteVideoPlayer:remoteVideoPlayer playTime:playTime];
    }
}
/// 加载状态改变
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer playItemStatus:(AVPlayerItemStatus)playItemStatus {
    if (playItemStatus == AVPlayerItemStatusReadyToPlay) {
        _isLoadingVideo = NO;
        _remoteVideoPlayer.backgroundColor = [UIColor blackColor];
        [self updateTimeShowView:_remoteVideoPlayer.currentPlaySeconds];
        [self.loadingAcitvityIndicator stopAnimation];
        if (_isAutoStartPlayAfterReady) {
            [self startPlay];
        }

    } else if (playItemStatus == AVPlayerItemStatusFailed) {
        [self showErrorMsg:@"网络异常, 请检查网络~"];
        _hasConfigPlayUrl = NO;
        _isLoadingVideo = NO;
        [self.loadingAcitvityIndicator stopAnimation];
        [self updatePlayControlView:NO contolType:self.playControlType];
    }
}
/// 播放状态改变
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer isPlaying:(BOOL) isPlaying {
    [self updatePlayControlView:isPlaying contolType:self.playControlType];
    if (isPlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didStartPlayPlayerControlView:)]) {
            [self.delegate didStartPlayPlayerControlView:self];
        }
    }
}

#pragma mark - 事件处理
- (void) onSliderValueStartChange:(UISlider *)slider {
    _isSliderChanging = YES;
    _isPlayDoneSliderAction = _remoteVideoPlayer.isPlaying;
    [_remoteVideoPlayer stopPlay];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}


- (void) onSliderValueDidChanged:(UISlider *)slider {
    if (!_hasConfigPlayUrl) {
        [_remoteVideoPlayer configPlayer:_playUrl];
        _hasConfigPlayUrl = YES;
        slider.value = 0.0;
        return;
    }
    
    NSTimeInterval totalSeconds = _remoteVideoPlayer.totalSeconds;
    if (totalSeconds > 0) {
        NSTimeInterval seekSeconds = totalSeconds * slider.value;
        self.progressView.progress = slider.value;
        [self updateTimeShowView:seekSeconds];
    }
}

- (void) onSliderDoneAction:(UISlider *)slider {
    _isSliderChanging = NO;
    NSTimeInterval totalSeconds = _remoteVideoPlayer.totalSeconds;
    if (totalSeconds > 0) {
        NSTimeInterval seekSeconds = totalSeconds * slider.value;
        [_remoteVideoPlayer seek:seekSeconds completionHandler:^(BOOL finished) {
            if (_isPlayDoneSliderAction) {
                _isPlayDoneSliderAction = NO;
                [_remoteVideoPlayer startPlay];
            }
            if ([self.delegate respondsToSelector:@selector(remoteVideoPlayer:moveToTime:)]) {
                [self.delegate remoteVideoPlayer:self.remoteVideoPlayer moveToTime:seekSeconds];
            }
        }];
    }
}
- (void) onButtonClickFullView:(UIButton *)sender {
    
}

- (void) onButtonStopAndPlay:(UIButton *)sender {
    _isSliderChanging = NO;
    if (_playUrl.length == 0) {
        [self showErrorMsg:@"没有视频播放链接~~"];
        return;
    }
    if (_remoteVideoPlayer.isPlaying) {
        if (_delegate && [_delegate respondsToSelector:@selector(playerControlView:onButtonPlay:)]) {
            [_delegate playerControlView:self onButtonPlay:NO];
        }
        [_remoteVideoPlayer stopPlay];
    } else {
        if (self.isLoadingVideo) { /// 加载中变为停止播放状态
            if (_delegate && [_delegate respondsToSelector:@selector(playerControlView:onButtonPlay:)]) {
                [_delegate playerControlView:self onButtonPlay:NO];
            }
            [self updatePlayControlView:NO contolType:self.playControlType];
            self.isAutoStartPlayAfterReady = NO;
            self.isLoadingVideo = NO;
        } else {
            if (_delegate && [_delegate respondsToSelector:@selector(playerControlView:onButtonPlay:)]) {
                [_delegate playerControlView:self onButtonPlay:YES];
            }
            if (![_remoteVideoPlayer readyToPlay]) {
                if (_hasConfigPlayUrl == NO) {
                    [self configPlayerWithPlayUrl:_playUrl isStartPlay:YES];
                } else {
                    _isLoadingVideo = YES;
                    _isAutoStartPlayAfterReady = YES;
                    [self updatePlayControlView:YES contolType:self.playControlType];
                }
                return;
            }
            [_remoteVideoPlayer startPlay];
        }
    }
}

- (void)onClickFullScreen:(UIButton *)sender
{
    [super onClickFullScreen:sender];
    if ([self.delegate respondsToSelector:@selector(playerControlView:onFullScreenClick:)]) {
        [self.delegate playerControlView:self onFullScreenClick:self.fullScreenButton.selected];
    }
}

#pragma mark getter setter
- (DSRightIndicatorAndLeftTextView *) loadingAcitvityIndicator {
    if (_loadingAcitvityIndicator == nil) {
        _loadingAcitvityIndicator = [DSRightIndicatorAndLeftTextView showInView:self withString:@"加载中..."];
    }
    return _loadingAcitvityIndicator;
}

- (UILabel *) errorLabel {
    if (_errorLabel == nil) {
        _errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        _errorLabel.backgroundColor = ColorOfHexAndAlpha(0x000000, 0.6);
        _errorLabel.font = [UIFont systemFontOfSize:12.0];
        _errorLabel.textColor = [UIColor whiteColor];
        _errorLabel.text = @"网络不稳定,缓冲再播放~";
        _errorLabel.layer.cornerRadius = 5.0;
        _errorLabel.clipsToBounds = YES;
    }
    return _errorLabel;
}

@end
