//
//  ICViewController.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICViewController.h"
#import "ICGestureRecognizer.h"
#import "ICPathView.h"
#import "ICTouch.h"
#import "ICPath.h"

@interface ICViewController ()

@property(nonatomic, strong) ICGestureRecognizer *gestureRecognizer;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation ICViewController

@synthesize gestureRecognizer = _IC_gestureRecognizer;
@synthesize pathView = _IC_pathView;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer 
{
    self.pathView.paths = [(ICGestureRecognizer *)gestureRecognizer bezierPaths];
    
    NSArray *icPaths = [(ICGestureRecognizer *)gestureRecognizer paths];
    NSTimeInterval minTime = 0;
    NSTimeInterval maxTime = 0;
    for (ICPath *path in icPaths) {
        for (ICTouch *touch in [path allTouches]) {
            if (minTime == 0 || [touch.timestamp doubleValue] < minTime) {
                minTime = [touch.timestamp doubleValue];
            }
            if (maxTime == 0 || [touch.timestamp doubleValue] > maxTime) {
                maxTime = [touch.timestamp doubleValue];
            }
        }
    }
    
    for (ICPath *path in icPaths) {
        [path computeAttributes];
    }
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.gestureRecognizer = [[ICGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    self.pathView.multipleTouchEnabled = YES;
    [self.pathView addGestureRecognizer:self.gestureRecognizer];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.gestureRecognizer = nil;
    self.pathView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
