//
//  DSVideoPlayView.h
//  DemoTest
//
//  Created by Apple on 15/9/8.
//  Copyright (c) 2015年 xiuxiukeji. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DSVideoPlayView;
@protocol DSVideoPlayViewDelegate <NSObject>

@optional
- (void) videoPlayView:(DSVideoPlayView *)videoPlayView playCallBack:(long)playTime;
// 播放完成回调
- (void) videoDonePlayVideoPlayView:(DSVideoPlayView *)videoPlayView;

- (void) videoPlayView:(DSVideoPlayView *)videoPlayView playItemStatus:(AVPlayerItemStatus)playItemStatus;

/// 播放状态改变
- (void) videoPlayView:(DSVideoPlayView *)videoPlayView isPlaying:(BOOL) isPlaying;
@end

@interface DSVideoPlayView : UIView
@property (weak, nonatomic) id<DSVideoPlayViewDelegate> delegate;

/// 是否被邀请录音
@property (nonatomic, assign) BOOL isInvitedCooperation;
/// 自己邀请自己的半成品url
@property (nonatomic, strong) NSString *selfCooperWorkFilePath;

/// 合作ID
@property (nonatomic, strong) NSString *cooperationID;
/// 设置视频显示方式
- (void) changeVideoGravity:(NSString *)videoGravity;
/// 是否在播放
@property (assign, readonly) BOOL isPlaying;
@property (nonatomic, assign) CGFloat totalSeconds;// 视频长度
- (NSTimeInterval) currentPlaySeconds;
@property (nonatomic, assign) long currentPlayTime;
/// 初始化视频播放视图
- (void) configAVPlayer:(NSString *)strUrl;
/// 增加背景音
- (void) addBackgroundAudioWithUrl:(NSString *) audioPath;
/// 添加原声录音原声 , 假如有录音则删除录音
- (void) addOriginalAudioWithDubbingType:(DSDubbingType)dubbingType;
/// 添加视频原声，（不是录音）原声播放
- (void) addVideoOriginalAudio;
/// 添加背景音
- (void) addBackgroundAudio;
/// 删除背景音
- (void) removeBackgroundAudio;
/// 是否有背景音
- (BOOL) hasBackgroundAudio;
/// 添加配音 假如有原声则去除
- (void) addDubbingAudio:(NSString *)recordAudio hasBackgroundAudio:(BOOL)hasBackground;
/// 录音开始处理，去除原声和录音
- (void) configPlayerForRecording:(BOOL)hasBackgroundAudio;

/// 删除配音音效
- (void) removeDubbingAudio;
/// 初始化录音页面视频播放
- (void) configRecordAVPlayer;
-(void)play;
-(void)pause;
-(void)seek:(long)mlStartTime completionHandler:(void (^)(BOOL finished))completionHandler;
/// 因为有timer 不使用一定要调用该方法
-(void)destroyPlayback;
/// 获取视频缩图列表
- (NSArray *) videoThumbImagesWithDuration:(NSTimeInterval)duration;
/// 获取第一帧图片
- (UIImage *) videoFirstThumbImage;
@end
