RDDRotationControlSurface

RDDRotationControlSurface is a simple, generic UIView subclass that acts a little bit like a UIGestureRecognizer, in that it exists simply to interpret touches and pass along the results to another delegate object. It is designed for generating angles of rotation from single finger rotation gestures and includes inertial deceleration. Because of the deceleration factor which continues AFTER all touch interaction has ended, this object was not a good candidate for a gesture recognizer (AFAIK).

Sample code uses ARC, and should run on iOS 4.3 and up.

TO USE:
	1. Add an RDDRotationControlSurface view into the desired gesture area of your view hierarchy.
	2. Set a delegate and at least implement rotationDidChangeByAngle:

WATCH OUT
	Two design choices which may change the way you interact with the API:
	1. The angles which are calculated are in DEGREES, not radians, and they are based on a full circle 360 degrees of positive rotation, rather than on the standard unit circle which consists of 0 to 180 degrees on the "top half" and 0 through -180 degrees on the bottom. What this amounts to is a coordinate system like this: 0 degrees to the right, 90 at top, 180 degrees to the left, and 270 down. If you only register for the rotationDidChangeByAngle: delegate method, the coordinate system doesn't make any difference anyway.
	2. RDDRotationControlSurface is designed to be able to track rotations of over 360 degrees, so the _touchAngle and _angleOfRotation are separate. _touchAngle gives the absolute, 0-360 degree angle, while _angleOfRotation is based on the entire amount of rotation since the touch began, and therefore can be more than 360 degrees as well as positive or negative.


https://github.com/rdsquared09/CircularScrollInertia