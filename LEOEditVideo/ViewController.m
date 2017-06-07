//
//  ViewController.m
//  LEOEditVideo
//
//  Created by leo on 2017/5/10.
//  Copyright © 2017年 LEO. All rights reserved.
//

#import "ViewController.h"
#import "LEOVideoTrimmerView.h"

@interface ViewController ()<LEOVideoTrimmerViewDelegate>

@property(nonatomic, strong)AVURLAsset *videoAsset;

@property(nonatomic, strong)LEOVideoTrimmerView *videoTrimmerView;

@property(nonatomic, strong)UIView *videoView;
@property(nonatomic, strong)AVPlayer *player;
@property(nonatomic, strong)AVPlayerItem *playerItem;
@property(nonatomic, strong)AVPlayerLayer *playerLayer;
@property(nonatomic, strong)AVAssetExportSession  *exportSession;
@property(nonatomic, assign)CGFloat videoFPS;

@property(nonatomic, assign)CGFloat startTime;
@property(nonatomic, assign)CGFloat stopTime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.minLength = 2.0;
    self.maxLength = 10.0;
    
    self.startTime = 0.0;
    self.stopTime = self.maxLength;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"spider-man" ofType:@"mp4"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    self.videoAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    self.videoFPS = [[[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate] * 1000.0;

    self.videoView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.videoView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.videoView];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.videoAsset];
    
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.videoView.bounds;

    [self.videoView.layer addSublayer:self.playerLayer];

    self.videoTrimmerView = [[LEOVideoTrimmerView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds) - 49, CGRectGetWidth([UIScreen mainScreen].bounds), 49) videoAsset:self.videoAsset maxLength:self.maxLength minLength:self.minLength];
    self.videoTrimmerView.delegate = self;
    [self.view addSubview:self.videoTrimmerView];
    [self.player play];
    
    
    __weak ViewController *weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        if (current >= self.stopTime) {
            [weakSelf.player seekToTime:CMTimeMakeWithSeconds(weakSelf.startTime, weakSelf.player.currentTime.timescale)];
            [weakSelf.videoTrimmerView resetTrackerViewAnimation];
        }
    }];
    
}

- (void)saveEditVideo {
    NSString *tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov.mov"];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.videoAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:self.videoAsset presetName:AVAssetExportPresetPassthrough];
        NSURL *furl = [NSURL fileURLWithPath:tempVideoPath];

        self.exportSession.outputURL = furl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMake(self.startTime * self.videoFPS, self.videoFPS);
        CMTime duration = CMTimeMake((self.stopTime - self.startTime) * self.videoFPS, self.videoFPS);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    
                    NSLog(@"Export canceled");
                    break;
                default: AVAssetExportSessionStatusCompleted:
                    NSLog(@"Export completed");
                    break;
            }
        }];
    }

}

- (void)trimmerViewBeginDragging:(LEOVideoTrimmerView *)trimmerView {
    [self.player pause];
}

- (void)trimmerViewEndDragging:(LEOVideoTrimmerView *)trimmerView {
    [self.player play];
}

- (void)trimmerView:(LEOVideoTrimmerView *)trimmerView
    changeStartTime:(CGFloat)startTime
            endTime:(CGFloat)endTime {
    self.startTime = startTime;
    self.stopTime = endTime;

    [self.player seekToTime:CMTimeMake(self.startTime * self.videoFPS, self.videoFPS) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

@end
