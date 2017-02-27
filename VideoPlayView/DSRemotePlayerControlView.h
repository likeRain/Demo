//
//  DSRemotePlayerControlView.h
//  DemoTest
//
//  Created by Apple on 15/12/28.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSBasePlayerControlView.h"

@class DSRemoteVideoPlayer;
@class DSRemotePlayerControlView;
@protocol DSRemotePlayerControlViewDelegate <NSObject>

@optional
- (void) playerControlView:(DSRemotePlayerControlView *)playerControlView onButtonPlay:(BOOL) isPlay;
- (void) didStartPlayPlayerControlView:(DSRemotePlayerControlView *)playerControlView;
- (void) playerControlViewDoneVideoPlay:(DSRemotePlayerControlView *)playerControlView;
- (void) playerControlView:(DSRemotePlayerControlView *)playerControlView onFullScreenClick:(BOOL) toFullScreen;
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer playTime:(NSTimeInterval)playTime;
- (void) remoteVideoPlayer:(DSRemoteVideoPlayer *)remoteVideoPlayer moveToTime:(NSTimeInterval)movedTime;
@end

@interface DSRemotePlayerControlView : DSBasePlayerControlView
@property (nonatomic, weak) id<DSRemotePlayerControlViewDelegate> delegate;

@property (nonatomic, strong, readonly) DSRemoteVideoPlayer *remoteVideoPlayer;
/// 添加外挂字幕，通过网络连接
- (void) showSubtitleWithSrtUrl:(NSString *)srtUrl;
/// 本地连接添加播放字幕
- (void) addSubtitleWithSrtFilePath:(NSString *)filePath withVideoShowSize:(CGSize)showSize;
/// 更新字幕播放视频显示尺寸
- (void) updateSubtitleViewWithShowVideoSize:(CGSize)showSize;
/// 控件类型
- (void) configControlType:(DSPlayControlType) playControlType thumbImageUrl:(NSString *)thumbImageUrl;
/// 配置播放链接
- (void) configPlayerWithPlayUrl:(NSString *)playUrl isStartPlay:(BOOL)isStartPlay;
/// 开始播放 play
- (void) startPlay;
- (void) stopPlay;
@end
