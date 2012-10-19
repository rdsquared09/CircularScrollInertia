//
//  RDDRotationControl.h
//  RotaryControlTests
//
//  Created by Ryan Dillon on 5/8/11.
//  Copyright 2012 Ryan Dillon. All rights reserved.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
/*****************************************************************/
// Summary:
//  Does not provide any UI. Designed to be an invisible view that overlays
//  any kind of button, knob, image, etc. and measures angle,
//  of a single touch in relation to the center of the view.
//  Information about the angle and rotation is then sent to a delegate object.
/*****************************************************************/

#import <Foundation/Foundation.h>


@protocol RDDRotationControlSurfaceDelegate <NSObject>
@optional

-(void)trackingDidBeginAtAbsoluteAngle:(CGFloat)angle;
-(void)rotationDidChangeByAngle:(CGFloat)angle;            // Just report the change since the last cycle.
-(void)trackingDidEndAtAbsoluteAngle:(CGFloat)angle withDeceleration:(BOOL)decelerating; // If deceleration is YES, then the delegate knows that subsequent rotationDidChangeByAngle calls are coming from the deceleration.
-(void)decelerationDidEnd;
-(void)trackingCanceled;

@end


@interface RDDRotationControlSurface : UIView {
    id<RDDRotationControlSurfaceDelegate> IBOutlet __unsafe_unretained delegate;
}

@property (nonatomic, unsafe_unretained) id<RDDRotationControlSurfaceDelegate> delegate;
@property (assign) BOOL inertiaEnabled;

@end
