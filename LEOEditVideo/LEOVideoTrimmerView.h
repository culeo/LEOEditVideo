//
//  LEOVideoTrimmerView.h
//  LEOEditVideo
//
//  Created by leo on 2017/5/10.
//  Copyright © 2017年 LEO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class LEOVideoTrimmerView;

@protocol LEOVideoTrimmerViewDelegate <NSObject>

@optional
- (void)trimmerViewBeginDragging:(LEOVideoTrimmerView *)trimmerView;
- (void)trimmerViewEndDragging:(LEOVideoTrimmerView *)trimmerView;
- (void)trimmerView:(LEOVideoTrimmerView *)trimmerView
    changeStartTime:(CGFloat)startTime
            endTime:(CGFloat)endTime;
@end

@interface LEOVideoTrimmerView : UIView

@property(nonatomic, weak)id<LEOVideoTrimmerViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame
                   videoAsset:(AVAsset *)videoAsset
                    maxLength:(CGFloat)maxLength
                    minLength:(CGFloat)minLength;

- (void)resetTrackerViewAnimation;

@end
