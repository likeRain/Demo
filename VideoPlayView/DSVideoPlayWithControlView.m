//
//  DSVideoPlayWithControlView.m
//  DemoTest
//
//  Created by zhoujianguang on 15/10/10.
//  Copyright © 2015年 xiuxiukeji. All rights reserved.
//

#import "DSVideoPlayWithControlView.h"

#define NotificationLock CFSTR("com.apple.springboard.lockcomplete")

@interface DSVideoPlayWithControlView ()
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, assign) TimeRange limitPlayRange;

@end

@implementation DSVideoPlayWithControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self awakeFromNib];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), NotificationLock, NULL);
}

- (void)setLimitPlayRange:(TimeRange)limitPlayRange
{
    if (limitPlayRange.startTime < 0 || limitPlayRange.endTime < 0 || limitPlayRange.endTime - limitPlayRange.startTime <= 0.0) {
        return;
    }
    _limitPlayRange = limitPlayRange;
    [self updateTimeShow];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.clipsToBounds = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillGo2Background) name:@"applicationWillResignActive" object:nil];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), screenLockStateChanged, NotificationLock, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    
    UIView *content = [ToolBox getClassFromXib:@"DSVideoPlayControl" owner:self];
    content.frame = CGRectMake(0, 0, self.width, self.height);
    content.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:content];
    
    self.playSlider.value = 0;
    self.playSlider.minimumTrackTintColor = ColorOfHexAndAlpha(0xFD5800, 1);
    self.playSlider.maximumTrackTintColor = ColorOfHexAndAlpha(0x000000, 0.5);
    
    [self onPlayBtn:nil];
}

static void screenLockStateChanged(CFNotificationCenterRef center,void* observer,CFStringRef name,const void* object,CFDictionaryRef userInfo)
{
    DSVideoPlayWithControlView *obj = (__bridge DSVideoPlayWithControlView *)observer;
    
    NSString* lockstate = (__bridge NSString*)name;
    
    if ([lockstate isEqualToString:(__bridge  NSString*)NotificationLock]) {
        [obj onAppWillGo2Background];
        //locked
    } else {
        //lock state changed
    }
}

- (void)onAppWillGo2Background
{
    [self pause];
}

- (void)configAVPlayer:(NSURL *)playUrl
{
    [super configAVPlayer:playUrl];
    [self updateTimeShow];
}

- (void)seek:(NSTimeInterval)mlStartTime completionHandler:(void (^)(BOOL))completionHandler
{
    [super seek:mlStartTime completionHandler:^(BOOL success) {
        if (success) {
            [self updateTimeShow];
        }
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

- (IBAction)onSliderChanged:(UISlider *)sender
{
    NSTimeInterval playTime = sender.value * self.totalSeconds;
    
    if (self.limitPlayRange.endTime > 0) {//有限制范围
        playTime = sender.value * (self.limitPlayRange.endTime - self.limitPlayRange.startTime) + self.limitPlayRange.startTime;
    }
    [super seek:playTime completionHandler:nil];
    [self updateTextShow];
}

- (IBAction)onPlayBtn:(UIButton *)sender
{
    if (self.limitPlayRange.endTime > 0 && ! self.playBtn.hidden &&
            (self.currentPlayTime >= self.limitPlayRange.endTime || self.currentPlayTime + 1 < self.limitPlayRange.startTime)) {
        async_main(^{///播放时间在限制区域外面
            [self seek:self.limitPlayRange.startTime completionHandler:^(BOOL finished) {
                if (finished) {
                    [self onPlayBtn:nil];
                }
            }];
        });
        return;
    }
    
    self.playBtn.hidden = ! self.playBtn.hidden;
    if (self.playBtn.hidden) {
        [super play];
        self.playSlider.userInteractionEnabled = NO;
        if ([self.controlDelegate respondsToSelector:@selector(videoWillPlay:)]) {
            [self.controlDelegate videoWillPlay:self];
        }
        [self.playSlider setThumbImage:[ToolBox createImageWithColor:[UIColor clearColor] size:CGSizeMake(10, 10)] forState:UIControlStateNormal];
    }
    else {
        [super pause];
        self.playSlider.userInteractionEnabled = YES;
        if ([self.controlDelegate respondsToSelector:@selector(videoWillStop:)]) {
            [self.controlDelegate videoWillStop:self];
        }
        [self.playSlider setThumbImage:[UIImage imageNamed:@"ds_circle"] forState:UIControlStateNormal];
    }
}

- (void)play
{
    if (! self.isPlaying) {
        [self onPlayBtn:nil];
    }
}

- (void)pause
{
    if (self.isPlaying) {
        [self onPlayBtn:nil];
    }
}

- (void)updateTimeShow
{
    if (self.totalSeconds > 0) {
        self.playSlider.value = self.currentPlayTime / self.totalSeconds;
        
        if (self.limitPlayRange.endTime - self.limitPlayRange.startTime > 0.0) {//有限制范围，修改时间显示值
            NSTimeInterval time = MIN(self.limitPlayRange.endTime, MAX(self.currentPlayTime, self.limitPlayRange.startTime));
            self.playSlider.value = (time - self.limitPlayRange.startTime) / (self.limitPlayRange.endTime - self.limitPlayRange.startTime);
        }
    }
    [self updateTextShow];
}

- (void)updateTextShow
{
    if (self.totalSeconds > 0) {
        NSTimeInterval time = self.currentPlayTime;
        NSTimeInterval totalSeconds = self.totalSeconds;
        
        if (self.limitPlayRange.endTime - self.limitPlayRange.startTime > 0.0) {//有限制范围，修改时间显示值
            time = MIN(self.limitPlayRange.endTime, MAX(self.currentPlayTime, self.limitPlayRange.startTime));
            totalSeconds = self.limitPlayRange.endTime;
        }
        
        time = MIN(totalSeconds, time);
        self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld/%02ld:%02ld", [@(time) integerFor001] / 60, [@(time) integerFor001] % 60, [@(totalSeconds) integerFor001] / 60, [@(totalSeconds) integerFor001] % 60];
    }
}

- (void)fireCallBack
{
    [super fireCallBack];
    [self updateTimeShow];
    
    async_main(^{//播放时间超出限制区域后面
        if (self.limitPlayRange.endTime > 0.0 && self.currentPlayTime >= self.limitPlayRange.endTime) {
            [super pause];
            [self videoDidFinishPlay];
        }
    });
}

- (void)videoDidFinishPlay
{
    [super videoDidFinishPlay];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        if (self.playBtn.hidden) {
            [self onPlayBtn:nil];
        }
    });
}

@end
