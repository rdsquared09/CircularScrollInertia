//
//  RDDRotationControl.m
//
//  Created by Ryan Dillon on 10/18/12.
//  Copyright 2012 Ryan Dillon. All rights reserved.
//

#import "RDDRotationControlSurface.h"

#import <QuartzCore/QuartzCore.h>

#define MIN_DISTANCE 22.0f          // Has a fairly large dead spot in the center.
                                    // Want circular motion, not jumping around the center.

#define DECELERATION_RATE 0.97
#define MAX_VELOCITY 2000.0
#define MIN_VELOCITY 10.0


@interface RDDRotationControlSurface() {

    CGFloat     _angleOfRotation;   // Default is 0.0f;
    CGFloat     _touchAngle;        // Used to calculate the change in angle while rotating.
    CGFloat     _outsideRadiusDeadZone;
    CGPoint     _initialTouchPoint;


    // Inertial Scrolling
    BOOL _decelerating;
    NSTimeInterval _startTouchTime;
    NSTimeInterval _endTouchTime;
    CGFloat _angleChange;
    NSTimer *_inertiaTimer;
    CADisplayLink *_displayLink;
    CGFloat _animatingVelocity;
    
}

-(CGFloat)angleBetweenCenterAndPoint:(CGPoint)point;
-(CGFloat)squaredDistanceToCenter:(CGPoint)point;
-(CGFloat)squaredDistanceFromPoint:(CGPoint)beginning toPoint:(CGPoint)end;
-(void)cancelAllTracking;

@end

@implementation RDDRotationControlSurface

@synthesize delegate;

#pragma mark - Lifecycle

-(void)setup {
    _angleOfRotation = 0.0f;
    
    _outsideRadiusDeadZone = self.bounds.size.width/2.0f;
    self.backgroundColor = [UIColor clearColor];
    self.multipleTouchEnabled = NO;
    
    _decelerating = NO;
    _inertiaEnabled = YES;
}

-(void)dealloc {
    delegate = nil;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    [self setup];
    return self;
}

-(id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    [self setup];
	return self;
}

#pragma mark - Convenience
-(CGFloat)squaredDistanceFromPoint:(CGPoint)beginning toPoint:(CGPoint)end {
    
    CGFloat dx = beginning.x - end.x;
	CGFloat dy = beginning.y - end.y;
	CGFloat f = dx*dx + dy*dy;
    
    return f;
}

-(CGFloat)squaredDistanceToCenter:(CGPoint)point {
    
	CGPoint center = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
    return [self squaredDistanceFromPoint:point toPoint:center];
    
}

-(CGFloat)angleBetweenPoint:(CGPoint)pointOne andPoint:(CGPoint)pointTwo {
    
    CGFloat theAngle = atan2f(pointOne.y - pointTwo.y, pointTwo.x - pointOne.x) * 180.0f/M_PI;
        
    // atan2f() returns values based on a unit circle. We want to convert into a full 360 degrees rather than use any negative values.
    if (theAngle < 0) {
        theAngle += 360.0;
    }
	return theAngle;
}

-(CGFloat)angleBetweenCenterAndPoint:(CGPoint)point {
    CGPoint center = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
    return [self angleBetweenPoint:center andPoint:point];
}


#pragma mark - Touch Handlers
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_decelerating) {
        [self endDeceleration];
    }
    
    [self startInertiaTimer];
    
    _startTouchTime = _endTouchTime = [NSDate timeIntervalSinceReferenceDate];
    _angleChange = 0.0;
    
    CGPoint point = [[touches anyObject] locationInView:self];
    _initialTouchPoint = point;
    
    // If the touch is too close to the center, then don't track.
    CGFloat distance = [self squaredDistanceToCenter:point];
	if (sqrtf(distance) < MIN_DISTANCE){
		return;
    }
    
    // Calculate starting angle between the touch location and the center of the view
    CGFloat angle = [self angleBetweenCenterAndPoint:point];
    
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(trackingBeganAtAbsoluteAngle:)]) {
        [self.delegate trackingDidBeginAtAbsoluteAngle:angle];
    }
    
    // Reset angleOfRotation
    _angleOfRotation = 0.0;
    _touchAngle = angle;
    
    return;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self startInertiaTimer];
    
    CGPoint point = [[touches anyObject] locationInView:self];
    
    CGFloat newAngle = [self angleBetweenCenterAndPoint:point];
    
    // Add the difference between old angle and new angle to the rotation
    CGFloat change = newAngle - _touchAngle;
    
    // If the change shows a really big jump, that means we've crossed the 0 degree line, and we need to calculate differently.
    // I'm sure there's a different way to do this, seems hackish, but it works just fine.
    if (change > 100.0f) {
        change -=360.0f;
    }
    else if (change < -100.0f) {
        change +=360.0f;
    }
    
    [self recordMovementWithAngle:change time:[NSDate timeIntervalSinceReferenceDate]];
    
    if ([self squaredDistanceToCenter:point] > MIN_DISTANCE*MIN_DISTANCE) {
            _angleOfRotation += change;
            if (fabs(change) < 90.0f) {
                    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(rotationDidChangeByAngle:)]) {
                        [self.delegate rotationDidChangeByAngle:change];
                    }
            }
    }
    
    _touchAngle = newAngle;
    
    return;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self cancelInertiaTimer];
    
    CGPoint point = [[touches anyObject] locationInView:self];
    CGFloat angle = [self angleBetweenCenterAndPoint:point];
    
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(trackingDidEndAtAbsoluteAngle:)]) {
        [self.delegate trackingDidEndAtAbsoluteAngle:angle withDeceleration:_inertiaEnabled];
    }
    
    _angleOfRotation = 0.0f;
    _touchAngle = 0.0f;
    
    if (_inertiaEnabled) {
        [self beginDeceleration];
    }
}

-(void)cancelAllTracking {

    [self cancelInertiaTimer];
    
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(trackingCanceled)]) {
        [self.delegate trackingCanceled];
    }
    
    _angleOfRotation = 0.0f;
    _touchAngle = 0.0f;
    
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self cancelAllTracking];
}


#pragma mark - Inertia
-(void)recordMovementWithAngle:(CGFloat)angle time:(NSTimeInterval)time {
    
    _startTouchTime = _endTouchTime;
    _endTouchTime = time;
    _angleChange = angle;
    
}

-(CGFloat)velocity {
    
    CGFloat velocity = 0.0;
    
    // Speed = distance/time (degrees/seconds)
    if (_startTouchTime != _endTouchTime) {
        velocity = _angleChange/(_endTouchTime - _startTouchTime);
    }
    
    if (velocity > MAX_VELOCITY) {velocity = MAX_VELOCITY;}
    else if (velocity < -MAX_VELOCITY) {velocity = -MAX_VELOCITY;}
    
    return velocity;
}

-(void)beginDeceleration {
    
    CGFloat v = [self velocity];
//    NSLog(@"Velocity: %f", v);
    
    // Taking a risk here that the delegate will not change or be destroyed while we're in the middle of animating the deceleration
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(rotationDidChangeByAngle:)]) {
        if (v >= MIN_VELOCITY || v <= -MIN_VELOCITY) {
            _decelerating = YES;
            _animatingVelocity = v;
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(decelerationStep)];
            _displayLink.frameInterval = 1;
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        }
    }
}

-(void)decelerationStep {
    
    CGFloat newVelocity = _animatingVelocity * DECELERATION_RATE;
    CGFloat changeThisFrame = _animatingVelocity/60.0;
    
    if (newVelocity <= 0.0001 && newVelocity >= -0.0001) {
        [self endDeceleration];
    }
    
    else {
        _animatingVelocity = newVelocity;
        [self.delegate rotationDidChangeByAngle:changeThisFrame];
    }
    
}

-(void)endDeceleration {
    _decelerating = NO;
    [_displayLink invalidate], _displayLink = nil;
    
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(decelerationDidEnd)]) {
        [self.delegate decelerationDidEnd];
    }
}

-(void)startInertiaTimer {
    
    // Used to clear out movement once the user has stopped moving for the specified time period. Prevents "leftover" inertia if the user moves, but then stops moving before lifting their finger.
    if (_inertiaTimer) {
        [_inertiaTimer invalidate];
        _inertiaTimer = nil;
    }
    _inertiaTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(inertiaTimout) userInfo:nil repeats:NO];
}

-(void)cancelInertiaTimer {
    if (_inertiaTimer) {
        [_inertiaTimer invalidate], _inertiaTimer = nil;
    }
}

-(void)inertiaTimout {
    _inertiaTimer = nil;
    _startTouchTime = _endTouchTime = [NSDate timeIntervalSinceReferenceDate];
    _angleChange = 0;
}


@end
