//
//  YSLDraggingCardContainer.m
//  Crew-iOS
//
//  Created by yamaguchi on 2015/10/22.
//  Copyright © 2015年 h.yamaguchi. All rights reserved.
//

#import "YSLDraggingCardContainer.h"

static const CGFloat kPreloadViewCount = 3.0f;
static const CGFloat kSecondCard_Scale = 0.98f;
static const CGFloat kTherdCard_Scale = 0.96f;
static const CGFloat kCard_Margin = 7.0f;
static const CGFloat kDragCompleteCoefficient_width_default = 0.8f;
static const CGFloat kDragCompleteCoefficient_height_default = 0.6f;

typedef NS_ENUM(NSInteger, MoveSlope) {
    MoveSlopeTop = 1,
    MoveSlopeBottom = -1
};

@interface YSLDraggingCardContainer ()

@property (nonatomic, assign) MoveSlope moveSlope;
@property (nonatomic, assign) CGRect defaultFrame;
@property (nonatomic, assign) NSInteger loadedIndex;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *currentViews;
@property (nonatomic, assign) BOOL isInitialAnimation;

@end

@implementation YSLDraggingCardContainer

- (id)init
{
    self = [super init];
    if (self) {
        [self setUp];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cardViewTap:)];
        [self addGestureRecognizer:tapGesture];
        
        _canDraggingDirection = YSLDraggingDirectionLeft | YSLDraggingDirectionLeft;
    }
    return self;
}

- (void)setUp
{
    _moveSlope = MoveSlopeTop;
    _loadedIndex = 0.0f;
    _currentIndex = 0.0f;
    _currentViews = [NSMutableArray array];
}

#pragma mark -- Public

-(void)reloadContainerView
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [_currentViews removeAllObjects];
    _currentViews = [NSMutableArray array];
    [self setUp];
    [self loadNextView];
    _isInitialAnimation = NO;
    [self viewInitialAnimation];
}

- (void)movePositionWithDirection:(YSLDraggingDirection)direction isAutomatic:(BOOL)isAutomatic resetHandler:(void (^)())resetHandler
{
    [self cardViewDirectionAnimation:direction isAutomatic:isAutomatic resetHandler:resetHandler];
}

- (void)movePositionWithDirection:(YSLDraggingDirection)direction isAutomatic:(BOOL)isAutomatic
{
    [self cardViewDirectionAnimation:direction isAutomatic:isAutomatic resetHandler:nil];
}

- (UIView *)getCurrentView
{
    return [_currentViews firstObject];
}

#pragma mark -- Private

- (void)loadNextView
{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cardContainerViewNumberOfViewInIndex:)]) {
        NSInteger index = [self.dataSource cardContainerViewNumberOfViewInIndex:_loadedIndex];
        
        // all cardViews Dragging end
        if (index == _currentIndex) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cardContainerViewDidCompleteAll:)]) {
                [self.delegate cardContainerViewDidCompleteAll:self];
            }
            return;
        }
        
        // load next cardView
        if (_loadedIndex < index) {
            
            NSInteger preloadViewCont = index <= kPreloadViewCount ? index : kPreloadViewCount;
            
            for (NSInteger i = _currentViews.count; i < preloadViewCont; i++) {
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(cardContainerViewNextViewWithIndex:)]) {
                    UIView *view = [self.dataSource cardContainerViewNextViewWithIndex:_loadedIndex];
                    if (view) {
                        _defaultFrame = view.frame;
                        
                        [self addSubview:view];
                        [self sendSubviewToBack:view];
                        [_currentViews addObject:view];
                        
                        if (i == 1 && _currentIndex != 0) {
                            view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + kCard_Margin, _defaultFrame.size.width, _defaultFrame.size.height);
                            view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kSecondCard_Scale,kSecondCard_Scale);
                        }
                        
                        if (i == 2 && _currentIndex != 0) {
                            view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + (kCard_Margin * 2), _defaultFrame.size.width, _defaultFrame.size.height);
                            view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kTherdCard_Scale,kTherdCard_Scale);
                        }
                         _loadedIndex++;
                    }
                    
                }
            }
        }
        
        UIView *view = [self getCurrentView];
        if (view) {
            UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
            [view addGestureRecognizer:gesture];
        }
    }
}
- (void)cardViewDirectionAnimation:(YSLDraggingDirection)direction isAutomatic:(BOOL)isAutomatic resetHandler:(void (^)())resetHandler
{
    if (!_isInitialAnimation) { return; }
    UIView *view = [self getCurrentView];
    if (!view) { return; }
    
    __weak YSLDraggingCardContainer *weakself = self;
    if (direction == YSLDraggingDirectionDefault) {
        view.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.55
                              delay:0.0
             usingSpringWithDamping:0.6
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             view.frame = _defaultFrame;
                             
                             [weakself cardViewDefaultScale];
                         } completion:^(BOOL finished) {
                         }];
        
        return;
    }
    
    if (!resetHandler) {
        [_currentViews removeObject:view];
        _currentIndex++;
        [self loadNextView];
    }
    
    if (direction == YSLDraggingDirectionRight || direction == YSLDraggingDirectionLeft || direction == YSLDraggingDirectionBottom) {
        
        [UIView animateWithDuration:0.35
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             
                             if (direction == YSLDraggingDirectionLeft) {
                                 view.center = CGPointMake(-1 * (weakself.frame.size.width), view.center.y);
                                 
                                 if (isAutomatic) {
                                     view.transform = CGAffineTransformMakeRotation(-1 * M_PI_4);
                                 }
                             }
                             
                             if (direction == YSLDraggingDirectionRight) {
                                 view.center = CGPointMake((weakself.frame.size.width * 2), view.center.y);
                                 
                                 if (isAutomatic) {
                                     view.transform = CGAffineTransformMakeRotation(direction * M_PI_4);
                                 }
                             }
                             
                             if (direction == YSLDraggingDirectionBottom) {
                                 view.center = CGPointMake(view.center.x, (weakself.frame.size.height * 1.5));
                             }
                             
                             if (!resetHandler) {
                                 [weakself cardViewDefaultScale];
                             }
                         } completion:^(BOOL finished) {
                             if (!resetHandler) {
                                 [view removeFromSuperview];
                             } else  {
                                 if (resetHandler) { resetHandler(); }
                             }
                         }];
    }
    
    if (direction == YSLDraggingDirectionTop) {
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             
                             if (direction == YSLDraggingDirectionTop) {
                                 if (isAutomatic) {
                                     view.transform = CGAffineTransformScale(CGAffineTransformIdentity,1.03,0.97);
                                     view.center = CGPointMake(view.center.x, view.center.y + kCard_Margin);
                                 }
                             }
                             
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.35
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                                              animations:^{
                                                  view.center = CGPointMake(view.center.x, -1 * ((weakself.frame.size.height) / 2));
                                                  [weakself cardViewDefaultScale];
                                              } completion:^(BOOL finished) {
                                                  if (!resetHandler) {
                                                      [view removeFromSuperview];
                                                  } else  {
                                                      if (resetHandler) { resetHandler(); }
                                                  }
                                              }];
                         }];
    }
}

- (void)cardViewUpDateScale
{
    UIView *view = [self getCurrentView];
    
    float diff_w = fabs((view.center.x - (self.frame.size.width / 2)) / (self.frame.size.width / 2));
    float diff_h = fabs((view.center.y - (self.frame.size.height / 2)) / (self.frame.size.height / 2));
    float diff = diff_w > diff_h ? diff_w : diff_h;
    
    if (_currentViews.count == 2) {
        if (diff <= 1) {
            UIView *view = _currentViews[1];
            view.transform = CGAffineTransformIdentity;
            view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + (kCard_Margin - (diff * kCard_Margin)), _defaultFrame.size.width, _defaultFrame.size.height);
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kSecondCard_Scale + (diff * (1 - kSecondCard_Scale)),kSecondCard_Scale + (diff * (1 - kSecondCard_Scale)));
        }
    }
    if (_currentViews.count == 3) {
        if (diff <= 1) {
            {
                UIView *view = _currentViews[1];
                view.transform = CGAffineTransformIdentity;
                view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + (kCard_Margin - (diff * kCard_Margin)), _defaultFrame.size.width, _defaultFrame.size.height);
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kSecondCard_Scale + (diff * (1 - kSecondCard_Scale)),kSecondCard_Scale + (diff * (1 - kSecondCard_Scale)));
            }
            {
                UIView *view = _currentViews[2];
                view.transform = CGAffineTransformIdentity;
                view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + ((kCard_Margin * 2) - (diff * kCard_Margin)), _defaultFrame.size.width, _defaultFrame.size.height);
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kTherdCard_Scale + (diff * (kSecondCard_Scale - kTherdCard_Scale)),kTherdCard_Scale + (diff * (kSecondCard_Scale - kTherdCard_Scale)));
            }
        }
    }
}

- (void)cardViewDefaultScale
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cardContainderView:updatePositionWithDraggingView:draggingDirection:widthDiff:heightDiff:)]) {
        
        [self.delegate cardContainderView:self updatePositionWithDraggingView:[self getCurrentView]
                        draggingDirection:YSLDraggingDirectionDefault
                                widthDiff:0 heightDiff:0];
    }

    for (int i = 0; i < _currentViews.count; i++) {
        UIView *view = _currentViews[i];
        if (i == 0) {
            view.transform = CGAffineTransformIdentity;
            view.frame = _defaultFrame;
        }
        if (i == 1) {
            view.transform = CGAffineTransformIdentity;
            view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + kCard_Margin, _defaultFrame.size.width, _defaultFrame.size.height);
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kSecondCard_Scale,kSecondCard_Scale);
        }
        if (i == 2) {
            view.transform = CGAffineTransformIdentity;
            view.frame = CGRectMake(_defaultFrame.origin.x, _defaultFrame.origin.y + (kCard_Margin * 2), _defaultFrame.size.width, _defaultFrame.size.height);
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity,kTherdCard_Scale,kTherdCard_Scale);
        }
    }
}

- (void)viewInitialAnimation
{
    for (UIView *view in _currentViews) {
        view.alpha = 0.0;
    }
    
    UIView *view = [self getCurrentView];
    if (!view) { return; }
    __weak YSLDraggingCardContainer *weakself = self;
    view.alpha = 1.0;
    view.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.5f,0.5f);
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.transform = CGAffineTransformScale(CGAffineTransformIdentity,1.05f,1.05f);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.1
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              view.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.95f,0.95f);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.1
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseOut
                                                               animations:^{
                                                                   view.transform = CGAffineTransformScale(CGAffineTransformIdentity,1.0f,1.0f);
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   
                                                                   for (UIView *view in _currentViews) {
                                                                       view.alpha = 1.0;
                                                                   }
                                                                   
                                                                   [UIView animateWithDuration:0.25f
                                                                                         delay:0.01f
                                                                                       options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                                                                                    animations:^{
                                                                                        [weakself cardViewDefaultScale];
                                                                                    } completion:^(BOOL finished) {
                                                                                        weakself.isInitialAnimation = YES;
                                                                                    }];
                                                               }
                                               ];
                                          }
                          ];
                     }
     ];
}

#pragma mark -- Gesture Selector

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gesture locationInView:self];
        if (touchPoint.y <= self.frame.size.height / 2) {
            _moveSlope = MoveSlopeTop;
        } else {
            _moveSlope = MoveSlopeBottom;
        }
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
    
        CGPoint point = [gesture translationInView:self];
        CGPoint movedPoint = CGPointMake(gesture.view.center.x + point.x, gesture.view.center.y + point.y);
        gesture.view.center = movedPoint;
        
        [gesture.view setTransform:
         CGAffineTransformMakeRotation((gesture.view.center.x - (self.frame.size.width / 2)) / (self.frame.size.width / 2) * (_moveSlope * (M_PI/20)))];
        
        [self cardViewUpDateScale];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cardContainderView:updatePositionWithDraggingView:draggingDirection:widthDiff:heightDiff:)]) {
            if ([self getCurrentView]) {
                
                float diff_w = (gesture.view.center.x - (self.frame.size.width / 2)) / (self.frame.size.width / 2);
                float diff_h = (gesture.view.center.y - (self.frame.size.height / 2)) / (self.frame.size.height / 2);
                
                YSLDraggingDirection direction = YSLDraggingDirectionDefault;
                
                if (fabs(diff_h) > fabs(diff_w)) {
                    
                    if (diff_h <= 0) {
                        // top
                        if (_canDraggingDirection & YSLDraggingDirectionTop) {
                            direction = YSLDraggingDirectionTop;
                        } else {
                            direction = diff_w <= 0 ? YSLDraggingDirectionLeft : YSLDraggingDirectionRight;
                        }
                    } else {
                        // bottom
                        if (_canDraggingDirection & YSLDraggingDirectionBottom) {
                            direction = YSLDraggingDirectionBottom;
                        } else {
                            direction = diff_w <= 0 ? YSLDraggingDirectionLeft : YSLDraggingDirectionRight;
                        }
                    }
                    
                } else {
                    if (diff_w <= 0) {
                        // left
                        if (_canDraggingDirection & YSLDraggingDirectionLeft) {
                            direction = YSLDraggingDirectionLeft;
                        } else {
                            direction = diff_h <= 0 ? YSLDraggingDirectionTop : YSLDraggingDirectionBottom;
                        }
                    } else {
                        // right
                        if (_canDraggingDirection & YSLDraggingDirectionRight) {
                            direction = YSLDraggingDirectionRight;
                        } else {
                            direction = diff_h <= 0 ? YSLDraggingDirectionTop : YSLDraggingDirectionBottom;
                        }
                    }
                    
                }
                
                [self.delegate cardContainderView:self updatePositionWithDraggingView:gesture.view
                                draggingDirection:direction
                                        widthDiff:fabs(diff_w) heightDiff:fabsf(diff_h)];
            }
        }
        
        [gesture setTranslation:CGPointZero inView:self];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled) {
        
        float diff_w = (gesture.view.center.x - (self.frame.size.width / 2)) / (self.frame.size.width / 2);
        float diff_h = (gesture.view.center.y - (self.frame.size.height / 2)) / (self.frame.size.height / 2);
        
        YSLDraggingDirection direction = YSLDraggingDirectionDefault;
        if (fabs(diff_h) > fabs(diff_w)) {
            if (diff_h < - kDragCompleteCoefficient_height_default && (_canDraggingDirection & YSLDraggingDirectionTop)) {
                // top
                direction = YSLDraggingDirectionTop;
            }
            
            if (diff_h > kDragCompleteCoefficient_height_default && (_canDraggingDirection & YSLDraggingDirectionBottom)) {
                // bottom
                direction = YSLDraggingDirectionBottom;
            }
            
        } else {
            
            if (diff_w > kDragCompleteCoefficient_width_default && (_canDraggingDirection & YSLDraggingDirectionRight)) {
                // Right
                direction = YSLDraggingDirectionRight;
            }
            
            if (diff_w < - kDragCompleteCoefficient_width_default && (_canDraggingDirection & YSLDraggingDirectionLeft)) {
                // Left
                direction = YSLDraggingDirectionLeft;
            }
        }
        
        if (direction == YSLDraggingDirectionDefault) {
            [self cardViewDirectionAnimation:YSLDraggingDirectionDefault isAutomatic:NO resetHandler:nil];
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cardContainerView:didEndDraggingAtIndex:draggingView:draggingDirection:)]) {
                [self.delegate cardContainerView:self didEndDraggingAtIndex:_currentIndex draggingView:gesture.view draggingDirection:direction];
            }
        }
        
    }
}

- (void)cardViewTap:(UITapGestureRecognizer *)gesture
{
    if (!_currentViews || _currentViews.count == 0) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(cardContainerView:didSelectAtIndex:draggingView:)]) {
        [self.delegate cardContainerView:self didSelectAtIndex:_currentIndex draggingView:gesture.view];
    }
}

@end