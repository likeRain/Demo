//
//  DSVideoPlayView.m
//  DemoTest
//
//  Created by Apple on 15/9/8.
//  Copyright (c) 2015年 xiuxiukeji. All rights reserved.
//

#import "DSVideoPlayView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "DSDownloadMgr.h"

@interface DSVideoPlayView ()
@property (nonatomic, strong) AVMutableComposition *avComposition; // 混音通道
@property (nonatomic, strong) AVURLAsset *avVideoAsset; // 视频资源
@property (nonatomic, strong) AVPlayerItem *playItem;
@property (nonatomic, strong) AVMutableCompositionTrack *originalAudioTrack;// 原声声道
@property (nonatomic, strong) AVMutableCompositionTrack *backgroundAudioTrack;// 背景音声道
@property (nonatomic, strong) AVMutableCompositionTrack *recordAudioTrack;// 录音声道
@property (nonatomic, strong) AVPlayer                  *player;
@property (nonatomic, strong) NSString                  *videoUrl;
@property (nonatomic, strong) id   playTimeHandler;
@property (nonatomic, strong) NSTimer  *timer;
@end

@implementation DSVideoPlayView

+ (Class) layerClass {
    return [AVPlayerLayer class];
}

-(void)setPlayer:(AVPlayer *)thePlayer{
    return [(AVPlayerLayer*)[self layer] setPlayer:thePlayer];
}

- (AVPlayer *) player {
    return ((AVPlayerLayer*)[self layer]).player;
}
#pragma mark 获取视频缩图列表
/// 获取视频缩图列表
- (NSArray *) videoThumbImagesWithDuration:(NSTimeInterval)duration {
    if (_avVideoAsset) {
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_avVideoAsset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.maximumSize = CGSizeMake(100, 100);
        NSError *error = nil;
        NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:100];
        for (CGFloat currentTime = 0; currentTime < self.totalSeconds; currentTime = currentTime + duration) {
            CMTime time = CMTimeMake(currentTime + 0.1,1);//缩略图创建时间 CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要活的某一秒的第几帧可以使用CMTimeMake方法)
            CMTime actucalTime; //缩略图实际生成的时间
            CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:&error];
            if (error) {
                DLog(@"截取视频图片失败:%@",error.localizedDescription);
            }
            CMTimeShow(actucalTime);
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            if (image == nil) {
                image = [UIImage imageNamed:@"ds_material_background"];
            }
            [imageArray addObject:image];
        }
        return imageArray;
    }
    return nil;
}
/// 获取第一帧图片
- (UIImage *) videoFirstThumbImage {
    if (_avVideoAsset) {
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:_avVideoAsset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.maximumSize = CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH);
        CMTime time = CMTimeMake(0,1);//缩略图创建时间 CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要活的某一秒的第几帧可以使用CMTimeMake方法)
        CMTime actucalTime; //缩略图实际生成的时间
        CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:nil];
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        return image;
    }
    return [UIImage imageNamed:@"ds_material_background"];
}

#pragma mark 视频处理
// 初始化视频播放视图
- (void) configAVPlayer:(NSString *)strUrl {
    if (self.originalAudioTrack) {
        [_avComposition removeTrack:_originalAudioTrack];
        _originalAudioTrack = nil;
    }
    if (self.recordAudioTrack) {
        [_avComposition removeTrack:_recordAudioTrack];
        self.recordAudioTrack = nil;
    }
    if (self.backgroundAudioTrack) {
        [_avComposition removeTrack:_backgroundAudioTrack];
        self.backgroundAudioTrack = nil;
    }
    self.videoUrl = strUrl;
    self.avComposition = [AVMutableComposition composition];
    //// 初始化视频媒体文件 options中可以指定要求准确播放时长
    self.avVideoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:strUrl] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]                                           forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
    NSArray * trackArray = [_avVideoAsset tracksWithMediaType:AVMediaTypeVideo];
    if (trackArray.count == 0) {
        
    } else {
        AVMutableCompositionTrack *compositionVideoTrack = [_avComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSError* error = nil;
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,_avVideoAsset.duration)
                                       ofTrack:[trackArray objectAtIndex:0]
                                        atTime:kCMTimeZero
                                         error:&error];
        if (self.player) {
            [self replacePlayItemForPlayer];
        } else {
            [self defaultInitPlayer];
        }
    }
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:VEDIO_PLAY_CALLBACK_TIME target:self selector:@selector(fireToGetCurrentTime) userInfo:nil repeats:YES];
    [self.timer setFireDate:[NSDate distantFuture]];
    _totalSeconds = CMTimeGetSeconds(_avVideoAsset.duration);
    [self seek:0 completionHandler:nil];

 }
/// 初始化录音页面视频播放
- (void) configRecordAVPlayer {
    NSString *documentDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"source"];
    NSString *videoPath = [documentDir stringByAppendingPathComponent:@"1.mp4"];
    NSFileManager * mgr = [NSFileManager defaultManager];
    if ([mgr fileExistsAtPath:videoPath]) {
        [self configAVPlayer:videoPath];
    }
}

// 获取当前时间
- (void) fireToGetCurrentTime {
    CMTime currentTime = self.player.currentItem.currentTime;
    //转成毫秒数
    long currentPlayMIMSTime = (long)(CMTimeGetSeconds(currentTime) * 1000);
    DLog(@"%ld",currentPlayMIMSTime);
    if (currentPlayMIMSTime < 0) {
        return;
    }
    async_main(^(void) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayView:playCallBack:)]) {
            [self.delegate videoPlayView:self playCallBack:currentPlayMIMSTime];
        }
        if (currentPlayMIMSTime >= (long)(self.totalSeconds * 1000)) {
            [self videoDidFinishPlay];
            DEBUG_NSLog(@"******************Play End  - CurrentTime Exceed Total Time ********************");
        }
    });
}

/// 设置视频显示方式
- (void) changeVideoGravity:(NSString *)videoGravity {
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    playerLayer.videoGravity = videoGravity;
}

#pragma mark 声道处理
/// 添加原声录音原声 , 假如有录音则删除录音
- (void) addOriginalAudioWithDubbingType:(DSDubbingType)dubbingType {
    if (self.originalAudioTrack) {
        return;
    }
    if (self.recordAudioTrack) {
        [_avComposition removeTrack:_recordAudioTrack];
        self.recordAudioTrack = nil;
    }
    if (self.backgroundAudioTrack) {
        [_avComposition removeTrack:_backgroundAudioTrack];
        self.backgroundAudioTrack = nil;
    }
    AVURLAsset *originalVideoAsset = _avVideoAsset;
    if (dubbingType == DSLiveCoorpInviteeDubbing || (dubbingType == DSCostaringDubbing && _isInvitedCooperation)) {// 被邀请实况， 原声取素材原声
        NSString *documentDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"source"];
        NSString *videoPath = [documentDir stringByAppendingPathComponent:@"1.mp4"];
        NSFileManager * mgr = [NSFileManager defaultManager];
        if ([mgr fileExistsAtPath:videoPath]) {
            originalVideoAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath]
                                                     options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
        }
    }
    
    NSArray * trackArray = [originalVideoAsset tracksWithMediaType:AVMediaTypeAudio];
    DLog(@"视频  时间%f",CMTimeGetSeconds(originalVideoAsset.duration));
    NSError* error = nil;
    if (trackArray.count == 0) {
        NSString *documentDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"source"];
        NSString * audioPath = [documentDir stringByAppendingPathComponent:@"1.mp3"];
        NSFileManager * mgr = [NSFileManager defaultManager];
        if([mgr fileExistsAtPath:audioPath]) {
            AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioPath] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
            NSArray *audioTracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
            if (audioTracks.count > 0) {
                self.originalAudioTrack = [_avComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                [_originalAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, originalVideoAsset.duration)
                                             ofTrack:[audioTracks objectAtIndex:0]
                                              atTime:kCMTimeZero
                                               error:&error];
            }
        }
    } else {
        self.originalAudioTrack = [_avComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [_originalAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,originalVideoAsset.duration)
                                       ofTrack:[trackArray objectAtIndex:0]
                                        atTime:kCMTimeZero
                                         error:&error];
    }
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }
}
/// 添加原声录音原声 , 假如有录音则删除录音(实况被邀请合作背景音)
- (void) addOriginalAudioForInviteeLiveDubbing {
    
}
/// 添加视频原声，（不是录音）原声播放
- (void) addVideoOriginalAudio {
    if (self.originalAudioTrack) {
        [_avComposition removeTrack:_originalAudioTrack];
        _originalAudioTrack = nil;
    }
    if (self.recordAudioTrack) {
        [_avComposition removeTrack:_recordAudioTrack];
        self.recordAudioTrack = nil;
    }
    if (self.backgroundAudioTrack) {
        [_avComposition removeTrack:_backgroundAudioTrack];
        self.backgroundAudioTrack = nil;
    }
    NSArray * trackArray = [_avVideoAsset tracksWithMediaType:AVMediaTypeAudio];
    DLog(@"视频  时间%f",CMTimeGetSeconds(_avVideoAsset.duration));
    NSError* error = nil;
    if (trackArray.count > 0) {
        self.originalAudioTrack = [_avComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [_originalAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,_avVideoAsset.duration)
                                     ofTrack:[trackArray objectAtIndex:0]
                                      atTime:kCMTimeZero
                                       error:&error];
    }
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }
}

/// 添加背景音
- (void) addBackgroundAudio {
    if (self.backgroundAudioTrack) {
        return;
    }
    [self initBackgroundAudioTrack];
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }
}
- (void) initBackgroundAudioTrack {
    if (self.backgroundAudioTrack) {
        return;
    }
    NSString * audioPath = @"";
    if (_isInvitedCooperation) {
        if (self.cooperationID == nil && self.selfCooperWorkFilePath) {
            audioPath = self.selfCooperWorkFilePath;
        } else {
            audioPath = [[DSDownloadMgr shareMgr] getCachePath:[NSString stringWithFormat:@"%@.mp4", _cooperationID] downloadType:DSDownloadCooLiveDubbing];
            if (![[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
                audioPath = [[DSDownloadMgr shareMgr] getCachePath:[NSString stringWithFormat:@"%@.mp3", _cooperationID] downloadType:DSDownloadCooDubbing];
            }
        }
    } else {
        NSString *documentDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"source"];
        audioPath = [documentDir stringByAppendingPathComponent:@"1x.mp3"];
    }
    [self createBackgroundTrack:audioPath];
}
// 创建被背景音声道
- (void) createBackgroundTrack:(NSString *)audioPath {
    NSError* error = nil;
    NSFileManager * mgr = [NSFileManager defaultManager];
    if (audioPath.length == 0) {
        return;
    }
    if ([mgr fileExistsAtPath:audioPath]) {
        AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioPath] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
        NSArray *audioTracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count > 0) {
            self.backgroundAudioTrack = [_avComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [self.backgroundAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _avVideoAsset.duration)
                                               ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0]
                                                atTime:kCMTimeZero
                                                 error:&error];
        }
    }
}


/// 删除背景音
- (void) removeBackgroundAudio {
    if ([self hasBackgroundAudio]) {
        [_avComposition removeTrack:_backgroundAudioTrack];
        self.backgroundAudioTrack = nil;
        if (self.player) {
            [self replacePlayItemForPlayer];
        } else {
            [self defaultInitPlayer];
        }
    }
}
/// 是否有背景音
- (BOOL) hasBackgroundAudio {
    if (self.backgroundAudioTrack) {
        return YES;
    }
    return NO;
}
/// 添加配音 假如有原声则去除
- (void) addDubbingAudio:(NSString *)recordAudio hasBackgroundAudio:(BOOL)hasBackground {
    if (self.recordAudioTrack) {
        [_avComposition removeTrack:_recordAudioTrack];
        self.recordAudioTrack = nil;
    }
    if (self.originalAudioTrack) {
        [_avComposition removeTrack:_originalAudioTrack];
        self.originalAudioTrack = nil;
    }
    if (hasBackground) {
        [self initBackgroundAudioTrack];
    } else {
        if ([self hasBackgroundAudio]) {
            [_avComposition removeTrack:_backgroundAudioTrack];
            self.backgroundAudioTrack = nil;
        }
    }
    NSFileManager * mgr = [NSFileManager defaultManager];
    NSError* error = nil;
    if ([mgr fileExistsAtPath:recordAudio]) {
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:recordAudio] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
        
        NSArray *audioTracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count > 0) {
            self.recordAudioTrack = [_avComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [_recordAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _avVideoAsset.duration) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:&error];
        }
    }
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }

}
/// 删除配音音效
- (void) removeDubbingAudio {
    if (self.recordAudioTrack) {
        [_avComposition removeTrack:_recordAudioTrack];
        self.recordAudioTrack = nil;
    }
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }
}


/// 录音开始处理，去除原声和录音
- (void) configPlayerForRecording:(BOOL)hasBackgroundAudio {
    if (hasBackgroundAudio) {
        if (!self.backgroundAudioTrack) {
            [self initBackgroundAudioTrack];
        } else {
            if (self.recordAudioTrack == nil && self.originalAudioTrack == nil) {// 声道正确不需要重现初始化（减少闪屏）
                return;
            }
        }
    } else {
        if (self.backgroundAudioTrack) {
            [_avComposition removeTrack:_backgroundAudioTrack];
            self.backgroundAudioTrack = nil;
        } else {
            if (self.recordAudioTrack == nil && self.originalAudioTrack == nil) {// 声道正确不需要重现初始化（减少闪屏）
                return;
            }
        }
    }
    if (self.recordAudioTrack) {
        [_avComposition removeTrack:_recordAudioTrack];
        self.recordAudioTrack = nil;
    }
    if (self.originalAudioTrack) {
        [_avComposition removeTrack:_originalAudioTrack];
        self.originalAudioTrack = nil;
    }
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }
}
- (void) replacePlayItemForPlayer {
    if (_playItem) {
        [self.playItem removeObserver:self forKeyPath:@"status"];
        self.playItem = nil;
    }
    _playItem = [AVPlayerItem playerItemWithAsset:_avComposition];
    [_playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.player replaceCurrentItemWithPlayerItem:_playItem];// 替换声道
}

- (void) defaultInitPlayer {
    if (self.player) {
        [self.player removeObserver:self forKeyPath:@"rate"];
        self.player = nil;
    }
    if (_playItem) {
        [self.playItem removeObserver:self forKeyPath:@"status"];
        self.playItem = nil;
    }
    _playItem = [AVPlayerItem playerItemWithAsset:_avComposition];
    self.player = [AVPlayer playerWithPlayerItem:_playItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doFinishPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [self.player addObserver:self
                  forKeyPath:@"rate"
                     options:NSKeyValueObservingOptionNew
                     context:(void*)kRateDidChangeKVO];
    // 播放加载状态回调
    [_playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}


/// 增加背景音
- (void) addBackgroundAudioWithUrl:(NSString *) audioPath {
    if (_backgroundAudioTrack) {
        [_avComposition removeTrack:_backgroundAudioTrack];
        self.backgroundAudioTrack = nil;
    }

    [self createBackgroundTrack:audioPath];
    if (self.player) {
        [self replacePlayItemForPlayer];
    } else {
        [self defaultInitPlayer];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
#pragma mark 播放进度
// 播放完成
- (void) doFinishPlay:(NSNotification *)item {
    if (item.object == self.player.currentItem) {
        [self videoDidFinishPlay];
        DEBUG_NSLog(@"******************Play End  - Notification ********************");
    }
}
//观察播放或录制的进度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    @try {
        if(kRateDidChangeKVO == (int)context){
            if ([keyPath isEqualToString:@"rate"]){
                BOOL isPlaying = YES;
                if (self.player.rate == 0.0){
                    [self.timer setFireDate:[NSDate distantFuture]];
                    isPlaying = NO;
                    CGFloat currentSeconds =  CMTimeGetSeconds(self.player.currentItem.currentTime);
                    if (currentSeconds >= self.totalSeconds) {
                        [self videoDidFinishPlay];
                        DEBUG_NSLog(@"******************Play End  - KVC - rate ********************");
                    }
                }
                if (_delegate && [_delegate respondsToSelector:@selector(videoPlayView:isPlaying:)]) {
                    [_delegate videoPlayView:self isPlaying:isPlaying];
                }
            }
        }
//        if ([keyPath isEqualToString:@"status"]) {
//            AVPlayerItemStatus oldState = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
//            AVPlayerItemStatus newState = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
//            if (oldState != newState) {
//                if (_delegate && [_delegate respondsToSelector:@selector(videoPlayView:playItemStatus:)]) {
//                    [_delegate videoPlayView:self playItemStatus:_playItem.status];
//                }
//            }
//        }
        
    } @catch (NSException *exception) {
    }
}


- (void)videoDidFinishPlay
{
    if (self.delegate && [_delegate respondsToSelector:@selector(videoDonePlayVideoPlayView:)]) {
        [_delegate videoDonePlayVideoPlayView:self];
    }
}

#pragma mark 播放操作相关

- (NSTimeInterval) currentPlaySeconds {
    return CMTimeGetSeconds(self.player.currentItem.currentTime);
}

- (long) currentPlayTime {
    //转成毫秒数
    _currentPlayTime = (long)(CMTimeGetSeconds(self.player.currentItem.currentTime) * 1000);
    return _currentPlayTime;
}

- (BOOL) isPlaying {
    if (self.player.rate == 0.0) {
        return NO;
    }
    return YES;
}

-(void)play {
    if (self.totalSeconds - 0.0 < 0.01) {
        [self configRecordAVPlayer];
        return;
    }
    if (self.isPlaying) {
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

-(void)pause {
    if (self.player.rate > 0) {
        [self.timer setFireDate:[NSDate distantFuture]];
        [self.player pause];
    }
}

-(void)seek:(long)mlStartTime completionHandler:(void (^)(BOOL finished))completionHandler {
    if (!self.player) {
        [self defaultInitPlayer];
    }
    [self.player seekToTime:CMTimeMake(mlStartTime, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}

-(void)destroyPlayback {
    if (self.player){
        [self.player removeObserver:self forKeyPath:@"rate"];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if (_playItem) {
            [self.playItem removeObserver:self forKeyPath:@"status"];
            self.playItem = nil;
        }
//        [self.player removeTimeObserver:self.playTimeHandler];
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
        [self.player pause];
        self.player = nil;
    }
}
- (CGFloat) totalSeconds {
    if (_totalSeconds < 0.001) {
        return 0.001;
    }
    return _totalSeconds;
}


- (void)dealloc {
    [self destroyPlayback];
}

@end
