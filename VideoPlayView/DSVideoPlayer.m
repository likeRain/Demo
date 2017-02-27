//
//  DSVideoPlayer.m
//  DemoTest
//
//  Created by zhoujianguang on 15/10/28.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import "DSVideoPlayer.h"

@interface DSVideoPlayer ()
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, weak) NSTimer  *timer;
@property (nonatomic, strong) AVPlayer *player;
@end

@implementation DSVideoPlayer

+ (Class) layerClass {
    return [AVPlayerLayer class];
}

-(void)setPlayer:(AVPlayer *)thePlayer{
    return [(AVPlayerLayer*)[self layer] setPlayer:thePlayer];
}

- (AVPlayer *) player {
    return ((AVPlayerLayer*)[self layer]).player;
}

// 初始化视频播放视图
- (void) configAVPlayer:(NSURL *)playUrl {
    
    self.asset = [AVAsset assetWithURL:playUrl];
    [self setPlayer:[AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.asset]]];
    self.totalSeconds = CMTimeGetSeconds(self.asset.duration);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidFinishPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidFinishPlay) name:AVPlayerItemFailedToPlayToEndTimeNotification object:self.player.currentItem];
}

#pragma mark 获取视频缩图列表
/// 获取视频缩图列表
- (NSArray *) videoThumbImagesWithDuration:(NSTimeInterval)duration {
    if (self.asset) {
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
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
            if (image) {
                [imageArray addObject:image];
            }
        }
        return imageArray;
    }
    return nil;
}

+ (void)thumbImageAtTime:(NSTimeInterval)thumbTime asset:(AVAsset *)asset size:(CGSize)size finish:(FinishBlock)finish
{
    if (! asset) {
        async_main(^{
            if (finish) {
                finish(NO, nil);
            }
        });
        return;
    }
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.maximumSize = size;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
    CMTime time = CMTimeMake(thumbTime * 1000.0, 1000);//缩略图创建时间
    async_global(^{
        CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:nil error:nil];
        async_main(^{
            if (finish) {
                if (cgImage) {
                    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];
                    finish(YES, returnImage);
                }
                else {
                    finish(NO, nil);
                }
            }
        });
    });
}

#pragma mark 播放操作相关

- (NSTimeInterval) currentPlayTime {
    _currentPlayTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
    return _currentPlayTime;
}

- (BOOL) isPlaying {
    if (self.player.rate == 0.0) {
        return NO;
    }
    return YES;
}

-(void)play {
    if (self.isPlaying) {
        return;
    }
    CMTime currentTime = self.player.currentItem.currentTime;
    //转成秒数
    NSTimeInterval currentPlayTime = CMTimeGetSeconds(currentTime);
    
    if (currentPlayTime + 0.01 >= self.totalSeconds) {
        [self seek:0 completionHandler:^(BOOL finished) {
            if (finished) {
                [self startTimer];
                [self.player play];
            }
        }];
        return;
    }
    [self startTimer];
    [self.player play];
}

-(void)pause {
    [self endTimer];
    [self.player pause];
}

-(void)seek:(NSTimeInterval)mlStartTime completionHandler:(void (^)(BOOL finished))completionHandler {
    [self.player seekToTime:CMTimeMake(mlStartTime * 1000.0, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}


- (void)videoDidFinishPlay
{
    [self endTimer];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDidFinishPlay:)]) {
        [self.delegate videoDidFinishPlay:self];
    }
}

- (void)fireCallBack {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayCallBackWithPlayer:)]) {
        [self.delegate videoPlayCallBackWithPlayer:self];
    }
    async_main(^{
        if (! self.isPlaying){
            [self videoDidFinishPlay];
        }
    });
}

- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:VEDIO_PLAY_CALLBACK_TIME target:self selector:@selector(fireCallBack) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)endTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)replaceWithDubbingAudio:(NSURL *)recordAudioUrl
{
    NSFileManager * mgr = [NSFileManager defaultManager];
    if ([mgr fileExistsAtPath:recordAudioUrl.path]) {
        
        AVMutableComposition *avComposition = [AVMutableComposition composition];
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:recordAudioUrl options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
        
        // 1 - Video track
        AVMutableCompositionTrack *videoTrack = [avComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.asset.duration)
                            ofTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
        // 2 - Audio track
        AVMutableCompositionTrack *audioTrack = [avComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)
                            ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
        
        [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:avComposition]];// 替换声道
    }
}


-(void)destroyPlayback {
    [self endTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.player){
        [self.player pause];
        self.player = nil;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self destroyPlayback];
    }
}

- (void)dealloc {
    
    [self destroyPlayback];
}



@end
