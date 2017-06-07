//
//  LEOVideoTrimmerView.m
//  LEOEditVideo
//
//  Created by leo on 2017/5/10.
//  Copyright © 2017年 LEO. All rights reserved.
//

#import "LEOVideoTrimmerView.h"

@interface LEOTrimmerThumbView : UIView

@property(nonatomic, assign, getter=isRight)BOOL right;

@end

@implementation LEOTrimmerThumbView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGRect bubbleFrame = self.bounds;
    
    [[UIColor clearColor] setFill];
    UIRectFill(bubbleFrame);
    
    CGRect roundedRectangleRect = CGRectZero;
    if (self.isRight) {
        roundedRectangleRect = CGRectMake(CGRectGetMaxX(bubbleFrame) - 10, CGRectGetMinY(bubbleFrame), 10, CGRectGetHeight(bubbleFrame));
    }
    else {
        roundedRectangleRect = CGRectMake(CGRectGetMinX(bubbleFrame), CGRectGetMinY(bubbleFrame), 10, CGRectGetHeight(bubbleFrame));
    }
    
    UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRect: roundedRectangleRect];
    [roundedRectanglePath closePath];
    [[UIColor whiteColor] setFill];
    [roundedRectanglePath fill];
    
    CGFloat lineViewHeight = 10.0;
    CGFloat lineViewWidth = 1.0;

    CGRect decoratingRect1 = CGRectMake(CGRectGetMinX(roundedRectangleRect) + 3,
                                       CGRectGetMidY(roundedRectangleRect) - lineViewHeight / 2.0,
                                       lineViewWidth,
                                       lineViewHeight);
    UIBezierPath *decoratingPath1 = [UIBezierPath bezierPathWithRoundedRect:decoratingRect1 byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerTopRight cornerRadii: CGSizeMake(0.5, 0.5)];
    [decoratingPath1 closePath];
    [[UIColor lightGrayColor] setFill];
    [decoratingPath1 fill];
    
    CGRect decoratingRect2 = CGRectMake(CGRectGetMinX(roundedRectangleRect) + 6,
                                        CGRectGetMidY(roundedRectangleRect) - lineViewHeight / 2.0,
                                        lineViewWidth,
                                        lineViewHeight);
    UIBezierPath *decoratingPath2 = [UIBezierPath bezierPathWithRoundedRect:decoratingRect2 byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerTopRight cornerRadii: CGSizeMake(0.5, 0.5)];
    [decoratingPath2 closePath];
    [[UIColor lightGrayColor] setFill];
    [decoratingPath2 fill];
}

@end

@interface LEOVideoTrimmerView()<UIScrollViewDelegate>

@property(nonatomic, strong)AVAsset *videoAsset;
@property(nonatomic, assign)CGFloat maxLength;
@property(nonatomic, assign)CGFloat minLength;

@property(nonatomic, strong)UIScrollView *scrollView;
@property(nonatomic, strong)UIView *contentView;
@property(nonatomic, strong)AVAssetImageGenerator *imageGenerator;

@property(nonatomic, strong)UIView *topBorderView;
@property(nonatomic, strong)UIView *bottomBorderView;
@property(nonatomic, strong)UIView *leftOverlayView;
@property(nonatomic, strong)UIView *rightOverlayView;
@property(nonatomic, strong)LEOTrimmerThumbView *leftThumbView;
@property(nonatomic, strong)LEOTrimmerThumbView *rightThumbView;

@property(nonatomic, strong)UIView *trackerView;

@property(nonatomic, assign)CGFloat perSecondWidth;

@property(nonatomic, assign)CGFloat marginWidth;
@property(nonatomic, assign)CGFloat thumbViewWidth;

@property(nonatomic, assign)CGPoint leftStartPoint;
@property(nonatomic, assign)CGPoint rightStartPoint;

@property(nonatomic, assign)CGFloat startTime;
@property(nonatomic, assign)CGFloat endTime;

@end

@implementation LEOVideoTrimmerView

- (instancetype)initWithFrame:(CGRect)frame
                   videoAsset:(AVAsset *)videoAsset
                    maxLength:(CGFloat)maxLength
                    minLength:(CGFloat)minLength {
    self = [super initWithFrame:frame];
    if (self) {
        self.videoAsset = videoAsset;
        self.maxLength = maxLength;
        self.minLength = minLength;
        self.marginWidth = 50;
        self.thumbViewWidth = 30;
        self.startTime = 0.0;
        self.endTime = self.maxLength;
        [self buildTrimmerView];
    }
    return self;
}

- (void)resetTrackerViewAnimation {
    [self trackerViewRemoveAnimation];
    [self trackerViewAddAnimation];
}

- (void)didChangeVideoRange {
    
    self.startTime =
    self.startTime = (CGRectGetMaxX(self.leftThumbView.frame) + self.scrollView.contentOffset.x - self.marginWidth) / self.perSecondWidth;
    
    self.endTime = (CGRectGetMinX(self.rightThumbView.frame) + self.scrollView.contentOffset.x - self.marginWidth) / self.perSecondWidth;

    if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerView:changeStartTime:endTime:)]) {
        [self.delegate trimmerView:self changeStartTime:self.startTime endTime:self.endTime];
    }
}

- (void)buildTrimmerView {
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.frame = CGRectMake(0,
                                       0,
                                       CGRectGetWidth(self.frame),
                                       CGRectGetHeight(self.frame));
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] init];
    self.contentView.clipsToBounds = YES;
    self.contentView.frame = CGRectMake(0,
                                        0,
                                        CGRectGetWidth(self.scrollView.frame),
                                        CGRectGetHeight(self.scrollView.frame));
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];
    
    self.topBorderView = [[UIView alloc] init];
    [self.topBorderView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:self.topBorderView];
    
    self.bottomBorderView = [[UIView alloc] init];
    [self.bottomBorderView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:self.bottomBorderView];
    
    self.leftOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.marginWidth, 49)];
    self.leftOverlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self addSubview:self.leftOverlayView];
    
    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame) - self.marginWidth, 0, self.marginWidth, 49)];
    self.rightOverlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self addSubview:self.rightOverlayView];

    self.leftThumbView = [[LEOTrimmerThumbView alloc] initWithFrame:CGRectMake(self.marginWidth - self.thumbViewWidth, 0, self.thumbViewWidth, 49)];
    self.leftThumbView.right = NO;
    UIPanGestureRecognizer *leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftThumbView:)];
    [self.leftThumbView addGestureRecognizer:leftPanGestureRecognizer];
    [self addSubview:self.leftThumbView];
    
    self.rightThumbView = [[LEOTrimmerThumbView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame) - self.marginWidth, 0, self.thumbViewWidth, 49)];
    self.leftThumbView.right = YES;
    UIPanGestureRecognizer *rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightThumbView:)];
    [self.rightThumbView addGestureRecognizer:rightPanGestureRecognizer];
    [self addSubview:self.rightThumbView];
    
    self.trackerView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.leftThumbView.frame) - 2, 0, 2, CGRectGetHeight(self.frame))];
    self.trackerView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    [self addSubview:self.trackerView];
    
    [self buildContentView];
    [self updateBorderViewFrames];
    [self trackerViewAddAnimation];
    
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self didChangeVideoRange];
}

- (void)trackerViewAddAnimation {
    self.trackerView.hidden = NO;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.fromValue = @(0);
    animation.toValue = @(CGRectGetMinX(self.rightThumbView.frame) - CGRectGetMaxX(self.leftThumbView.frame));
    animation.duration = self.endTime - self.startTime;
    animation.removedOnCompletion = NO;
    animation.repeatCount = 0;
    animation.fillMode = kCAFillModeForwards;
    [self.trackerView.layer addAnimation:animation forKey:@"transform.translation.x"];
}

- (void)trackerViewRemoveAnimation {
    [self.trackerView.layer removeAllAnimations];
    self.trackerView.hidden = YES;
}

- (void)moveLeftThumbView:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.leftStartPoint = [gesture locationInView:self];
            [self trackerViewRemoveAnimation];
            if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewBeginDragging:)]) {
                [self.delegate trimmerViewBeginDragging:self];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint point = [gesture locationInView:self];
            int deltaX = point.x - self.leftStartPoint.x;
            CGRect thumbViewFrame = self.leftThumbView.frame;
            thumbViewFrame.origin.x += deltaX;
            
            CGFloat thumbViewMaxX = CGRectGetMinX(self.rightOverlayView.frame) - (self.minLength * self.perSecondWidth);
            if (CGRectGetMaxX(thumbViewFrame) < self.marginWidth) {
                thumbViewFrame.origin.x = self.marginWidth - thumbViewFrame.size.width;
            }
            else if (CGRectGetMaxX(thumbViewFrame) > thumbViewMaxX){
                thumbViewFrame.origin.x = thumbViewMaxX - thumbViewFrame.size.width;
            }
            self.leftThumbView.frame = thumbViewFrame;
            self.leftOverlayView.frame = ({
                CGRect frame = self.leftOverlayView.frame;
                frame.size.width = CGRectGetMaxX(thumbViewFrame);
                frame;
            });
            self.leftStartPoint = point;
            [self updateBorderViewFrames];
            [self didChangeVideoRange];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            self.trackerView.frame = ({
                CGRect frame = self.trackerView.frame;
                frame.origin.x = CGRectGetMaxX(self.leftThumbView.frame);
                frame;
            });
            [self trackerViewAddAnimation];
            if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewEndDragging:)]) {
                [self.delegate trimmerViewEndDragging:self];
            }
            break;
        }
        default:
            break;
    }
}

- (void)moveRightThumbView:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.rightStartPoint = [gesture locationInView:self];
            [self trackerViewRemoveAnimation];
            if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewBeginDragging:)]) {
                [self.delegate trimmerViewBeginDragging:self];
            }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint point = [gesture locationInView:self];
            int deltaX = point.x - self.rightStartPoint.x;
            CGRect thumbViewFrame = self.rightThumbView.frame;
            thumbViewFrame.origin.x += deltaX;
            
            CGFloat thumbViewMinX = CGRectGetMaxX(self.leftThumbView.frame) + (self.minLength * self.perSecondWidth);
            if (CGRectGetMinX(thumbViewFrame) > (CGRectGetWidth(self.frame) - self.marginWidth)) {
                thumbViewFrame.origin.x = (CGRectGetWidth(self.frame) - self.marginWidth);
            }
            else if (CGRectGetMinX(thumbViewFrame) < thumbViewMinX){
                thumbViewFrame.origin.x = thumbViewMinX;
            }
            self.rightThumbView.frame = thumbViewFrame;
            self.rightOverlayView.frame = ({
                CGRect frame = self.rightOverlayView.frame;
                frame.origin.x = CGRectGetMinX(thumbViewFrame);
                frame.size.width = CGRectGetWidth(self.frame) - CGRectGetMinX(thumbViewFrame);
                frame;
            });
            self.rightStartPoint = point;
            [self updateBorderViewFrames];
            [self didChangeVideoRange];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            [self trackerViewAddAnimation];
            if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewEndDragging:)]) {
                [self.delegate trimmerViewEndDragging:self];
            }
            break;
        }
        default:
            break;
    }
}

- (void)updateBorderViewFrames {
    CGFloat borderHeight = 2;
    CGFloat borderWidth = CGRectGetMinX(self.rightThumbView.frame) - CGRectGetMaxX(self.leftThumbView.frame) + 2;
    CGFloat borderX = CGRectGetMaxX(self.leftThumbView.frame) - 1;
    
    self.topBorderView.frame = CGRectMake(borderX,
                                          0,
                                          borderWidth,
                                          borderHeight);
    self.bottomBorderView.frame = CGRectMake(borderX,
                                             CGRectGetHeight(self.frame) - borderHeight,
                                             borderWidth,
                                             borderHeight);
}

- (void)buildContentView {
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.videoAsset];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    self.imageGenerator.maximumSize = CGSizeMake(CGRectGetHeight(self.frame) * screenScale, CGRectGetHeight(self.frame) * screenScale);
    self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
    CGFloat imageViewWidth = (CGRectGetWidth(self.frame) - 2 * self.marginWidth)/10.0;
    CGFloat imageViewHeight = CGRectGetHeight(self.frame);
    //第一张图
    NSError *error;
    //实际时间
    CMTime actualTime;
    CGImageRef fistImageRef = [self.imageGenerator copyCGImageAtTime:kCMTimeZero
                                                          actualTime:&actualTime
                                                               error:&error];
    UIImage *fistImage = [[UIImage alloc] initWithCGImage:fistImageRef
                                                    scale:screenScale
                                              orientation:UIImageOrientationUp];
    if (fistImageRef != NULL) {
        UIImageView *fistImageView = [[UIImageView alloc] initWithImage:fistImage];
        fistImageView.frame = CGRectMake(0, 0, imageViewWidth, imageViewHeight);
        fistImageView.contentMode = UIViewContentModeScaleAspectFill;
        fistImageView.clipsToBounds = YES;
        [self.contentView addSubview:fistImageView];
        CGImageRelease(fistImageRef);
    }
    
    //视频长度
    Float64 videoLength = CMTimeGetSeconds([self.videoAsset duration]);
    //如果最大长度大于视频长度则设置最大长度等于视频长度
    if (self.maxLength > videoLength) {
        self.maxLength = videoLength;
    }
   
    //最大宽度(中间透明部分)
    CGFloat canUseWidth = CGRectGetWidth(self.frame) - self.marginWidth * 2;
    
    self.perSecondWidth = canUseWidth / (self.maxLength * 1.0);
    
    NSInteger actualLenght = ceil(self.perSecondWidth * videoLength / imageViewWidth);
    Float64 perLength = imageViewWidth/ self.perSecondWidth;

    self.contentView.frame = CGRectMake(self.marginWidth, 0, actualLenght * imageViewWidth, imageViewHeight);
    [self.scrollView setContentSize:self.contentView.frame.size];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.contentView.frame) + self.marginWidth * 2, 0);
    
    CGFloat videoFPS = [[[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate] * 1000;
    NSMutableArray *videoTimes = [[NSMutableArray alloc] init];
    for (int i =  1; i < actualLenght; i++){
        CMTime time = CMTimeMake(i * perLength * videoFPS, 24000);
        [videoTimes addObject:[NSValue valueWithCMTime:time]];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.tag = i;
        imageView.frame = CGRectMake( i * imageViewWidth,
                                      0,
                                      imageViewWidth,
                                      imageViewHeight);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentView addSubview:imageView];
        });
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 1; i<= [videoTimes count]; i++) {
            CMTime time = [((NSValue *)[videoTimes objectAtIndex:i - 1]) CMTimeValue];
            CGImageRef imageRef = [self.imageGenerator copyCGImageAtTime:time actualTime:nil error:nil];
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
            CGImageRelease(imageRef);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageView = (UIImageView *)[self.contentView viewWithTag:i];
                imageView.image = image;
            });
        }
    });
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self trackerViewRemoveAnimation];
    if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewBeginDragging:)]) {
        [self.delegate trimmerViewBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate) {
        return;
    }
    [self didChangeVideoRange];
    [self trackerViewAddAnimation];
    if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewEndDragging:)]) {
        [self.delegate trimmerViewEndDragging:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self didChangeVideoRange];
    [self trackerViewAddAnimation];
    if (self.delegate && [self.delegate respondsToSelector:@selector(trimmerViewEndDragging:)]) {
        [self.delegate trimmerViewEndDragging:self];
    }
}

@end
