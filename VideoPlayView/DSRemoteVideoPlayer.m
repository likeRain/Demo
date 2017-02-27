//
//  DSRemoteVideoPlayer.m
//  DemoTest
//
//  Created by Apple on 15/12/28.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import "DSRemoteVideoPlayer.h"

@interface DSRemoteVideoPlayer ()
@property (strong, nonatomic) AVPlayer       *player;
@property (strong, nonatomic) AVPlayerItem   *playerItem;
@property (strong, nonatomic) NSString       *playUrl;
@property (strong, nonatomic) NSTimer        *timer;
@end

@implementation DSRemoteVideoPlayer
#pragma mark  - 初始化方法
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (void) setPlayer:(AVPlayer *)player {
    [((AVPlayerLayer *)self.layer) setPlayer:player];
}
- (AVPlayer *) player {
    return ((AVPlayerLayer*)[self layer]).player;
}
#pragma mark - 公开方法
/// 配置播放器
- (void) configPlayer:(NSString *)playerUrl {
    [self releasePlayer];
    _playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:playerUrl]];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:_playerItem];
    [self setPlayer:player];
    // 播放速率回调
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    // 播放加载状态回调
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    // 完成播放回调
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(donePlay) name:AVPlayerItemDidPlayToEndTimeNotification object:self];
    // 播放进度回调处理
    self.timer = [NSTimer scheduledTimerWithTimeInterval:VEDIO_PLAY_CALLBACK_TIME target:self selector:@selector(timerFireMethod) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantFuture]];
    
}
/// 是否在播放
- (BOOL) isPlaying {
    if (self.player.rate == 0.0) {
        return NO;
    }
    return YES;
}

/// 重新播放
- (void) restartPlay
{
    if ([self isPlaying]) {
        [self.timer setFireDate:[NSDate distantFuture]];
        [self.player pause];
    }
    [self seek:0 completionHandler:^(BOOL finished) {
        if (finished) {
            [self.timer setFireDate:[NSDate date]];
            [self.player play];
        }
    }];
}

/// 开始播放
- (void) startPlay {
    if ([self isPlaying]) {
        return;
    }
    CMTime currentTime = self.player.currentItem.currentTime;
    //转成秒数
    CGFloat currentPlayTime = CMTimeGetSeconds(currentTime);
    
    if (currentPlayTime >= self.totalSeconds) {
        [self seek:0 completionHandler:^(BOOL finished) {
            if (finished) {
                [self.timer setFireDate:[NSDate date]];
                [self.player play];
            }
        }];
        return;
    }
    [self.timer setFireDate:[NSDate date]];
    [self.player play];
}
/// 停止播放
- (void) stopPlay {
    if (![self isPlaying]) {
        return;
    }
    
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.player pause];
}
/// 是否加载完成
- (BOOL) readyToPlay {
    return self.playerItem.status == AVPlayerItemStatusReadyToPlay;
}
///
-(void)destroyPlayback {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self releasePlayer];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/// 跳
-(void)seek:(NSTimeInterval)mlStartTime completionHandler:(void (^)(BOOL finished))completionHandler {
    if (![self readyToPlay] && _playerItem) {
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    if (!self.player) {
        [self configPlayer:_playUrl];
    }
    [self.player seekToTime:CMTimeMake(mlStartTime*1000, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}
/// 释放player
- (void) releasePlayer {
    if (self.player) {
        [self.player removeObserver:self forKeyPath:@"rate"];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.player pause];
        self.playerItem = nil;
        self.player = nil;
    }
}

#pragma mark - 私有方法

/// 完成播放
- (void) donePlay {
    if (self.delegate && [_delegate respondsToSelector:@selector(remoteVideoPlayerDonePlay:)]) {
        [_delegate remoteVideoPlayerDonePlay:self];
    }
}
/// timer 回调
- (void) timerFireMethod {
    async_main(^(void) {
        if (_delegate && [_delegate respondsToSelector:@selector(remoteVideoPlayer:playTime:)]) {
            [_delegate remoteVideoPlayer:self playTime:self.currentPlaySeconds];
        }
    });
}

- (NSTimeInterval) currentPlaySeconds {
    if ([self readyToPlay]) {
        _currentPlaySeconds = CMTimeGetSeconds(_playerItem.currentTime);
        return _currentPlaySeconds;
    }
    return 0.0;
}
- (NSTimeInterval) totalSeconds {
    if ([self readyToPlay]) {
        _totalSeconds = CMTimeGetSeconds(_playerItem.duration);
        if (self.player.currentItem.duration.value == 0 &&  self.player.currentItem.duration.timescale == 0) {
            _totalSeconds = 0.0;
        }
        return _totalSeconds;
    }
    return 0.0;
}
#pragma mark - 回调
/// 观察者回调
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    @try {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerItemStatus oldState = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
            AVPlayerItemStatus newState = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            if (oldState != newState) {
                if (_delegate && [_delegate respondsToSelector:@selector(remoteVideoPlayer:playItemStatus:)]) {
                    [_delegate remoteVideoPlayer:self playItemStatus:_playerItem.status];
                }
            }
        }
        if ([keyPath isEqualToString:@"rate"]) {
            BOOL isPlaying = YES;
            if (self.player.rate == 0.0) { // 播放停止
                isPlaying = NO;
                [self.timer setFireDate:[NSDate distantFuture]];
                if (self.readyToPlay) {
                    if (self.totalSeconds < self.currentPlaySeconds + 0.05) {
                        [self donePlay];
                    }
                }
            } else { // 播放中
                [self.timer setFireDate:[NSDate date]];
            }
            if (_delegate && [_delegate respondsToSelector:@selector(remoteVideoPlayer:isPlaying:)]) {
                [_delegate remoteVideoPlayer:self isPlaying:isPlaying];
            }
        }
    }
    @catch (NSException *exception) {
    }
    
}

- (void) dealloc {
    [self destroyPlayback];
}
@end
