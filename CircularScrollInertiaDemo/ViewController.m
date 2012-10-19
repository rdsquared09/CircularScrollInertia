//
//  ViewController.m
//  CircularScrollInertiaDemo
//
//  Created by Ryan Dillon on 10/18/12.
//  Copyright (c) 2012 Ryan Dillon. All rights reserved.
//

#import "ViewController.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)


@interface ViewController ()

@property IBOutlet UIImageView *theImage;

@end

@implementation ViewController

-(void)rotationDidChangeByAngle:(CGFloat)angle {
    self.theImage.transform = CGAffineTransformRotate(self.theImage.transform, degreesToRadians(-angle));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
