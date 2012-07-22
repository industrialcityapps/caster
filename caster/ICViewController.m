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

@interface ICViewController ()

@property(nonatomic, strong) ICGestureRecognizer *gestureRecognizer;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation ICViewController

@synthesize gestureRecognizer = _IC_gestureRecognizer;
@synthesize pathView = _IC_pathView;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer 
{
    self.pathView.paths = [(ICGestureRecognizer *)gestureRecognizer paths];
    [(ICGestureRecognizer *)gestureRecognizer fft];
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
