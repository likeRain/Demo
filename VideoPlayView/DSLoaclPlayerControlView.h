//
//  DSLoaclPlayerControlView.h
//  DemoTest
//
//  Created by Apple on 16/3/7.
//  Copyright © 2016年 xiuxiukeji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSBasePlayerControlView.h"


@interface DSLoaclPlayerControlView : DSBasePlayerControlView
/// 假如有字幕添加字幕
- (void) addPlaySubtitleViewifNeedWithShowSize:(CGSize)showSize withSrtUrl:(NSString *)srtUrl;
/// 删除字幕视图
- (void) removePlaySutitleView;
/// 更新字幕字幕显示大小
- (void) updateSubtitleViewShowSize:(CGSize)showSize;
/// 播放本地视频
- (void) configControlWithLocalUrl:(NSString *)playUrl andControlPlayerType:(DSPlayControlType)playerType;
/// 和背景音一起播放
- (void) configControlWithLocalUrl:(NSString *)playUrl andBackgroundAudioUrl:(NSString *)bkgAudioUrl andControlPlayerType:(DSPlayControlType)playerType;
/// 播放视频原声
- (void) configControlPlayOrgWithLocalUrl:(NSString *)playUrl withControlPlayerType:(DSPlayControlType)playerType;


@end
