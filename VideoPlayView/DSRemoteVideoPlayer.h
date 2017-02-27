//
//  DSRemoteVideoPlayer.h
//  DemoTest
//
//  Created by Apple on 15/12/28.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DSRemoteVideoPlayer;
@protocol DSRemoteVideoPlayerDelegate <NSObject>
@optional
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer playTime:(NSTimeInterval)playTime;
- (void) remoteVideoPlayerDonePlay:(DSRemoteVideoPlayer *)remoteVideoPlayer;
/// 加载状态改变
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer playItemStatus:(AVPlayerItemStatus)playItemStatus;
/// 播放状态改变
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer isPlaying:(BOOL) isPlaying;
@end

@interface DSRemoteVideoPlayer : UIView
@property (weak, nonatomic)   id<DSRemoteVideoPlayerDelegate> delegate;
@property (assign, nonatomic) NSTimeInterval  currentPlaySeconds;
@property (assign, nonatomic) NSTimeInterval  totalSeconds;


/// 跳
-(void)seek:(NSTimeInterval)mlStartTime completionHandler:(void (^)(BOOL finished))completionHandler;
/// 配置播放器
- (void) configPlayer:(NSString *)playerUrl;
/// 是否在播放
- (BOOL) isPlaying;
/// 重新播放
- (void) restartPlay;
/// 开始播放
- (void) startPlay;
/// 停止播放
- (void) stopPlay;
/// 是否加载完成
- (BOOL) readyToPlay;
///
-(void)destroyPlayback;
/// 释放player
- (void) releasePlayer;
@end
