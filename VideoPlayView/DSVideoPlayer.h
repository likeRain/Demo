//
//  DSVideoPlayer.h
//  DemoTest
//
//  Created by zhoujianguang on 15/10/28.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSVideoPlayer;
@protocol DSVideoPlayerDelegate <NSObject>
@optional
- (void) videoPlayCallBackWithPlayer:(DSVideoPlayer *)videoPlayView;
// 播放完成回调
- (void) videoDidFinishPlay:(DSVideoPlayer *)videoPlayView;
@end

@interface DSVideoPlayer : UIView
/// 是否在播放
@property (assign, readonly) BOOL isPlaying;
@property (nonatomic, assign) NSTimeInterval totalSeconds;// 视频长度
@property (nonatomic, assign) NSTimeInterval currentPlayTime;

@property (weak, nonatomic) id<DSVideoPlayerDelegate> delegate;
- (void) configAVPlayer:(NSURL *)playUrl;

-(void)play;
-(void)pause;
-(void)seek:(NSTimeInterval)mlStartTime completionHandler:(void (^)(BOOL finished))completionHandler;
/// 获取视频缩图列表
- (NSArray *) videoThumbImagesWithDuration:(NSTimeInterval)duration;
///高精确度的截图，建议转圈
+ (void)thumbImageAtTime:(NSTimeInterval)thumbTime asset:(AVAsset *)asset size:(CGSize)size finish:(FinishBlock)finish;

- (void)replaceWithDubbingAudio:(NSURL *)recordAudioUrl;

/**子类重载用，外部不能使用*/
- (void)videoDidFinishPlay;
- (void)fireCallBack;
@end
