//
//  ICPathView.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICPathView.h"

@implementation ICPathView

@synthesize paths = _IC_paths;
@synthesize generatedPaths = _IC_generatedPaths;

- (void)setPaths:(NSArray *)paths
{
    _IC_paths = paths;
    [self setNeedsDisplay];
}

- (void)setGeneratedPaths:(NSArray *)generatedPaths
{
    _IC_generatedPaths = generatedPaths;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] setStroke];
    
    for (UIBezierPath *path in self.paths) {
        path.lineWidth = 5;
        [[UIColor darkGrayColor] setStroke];
        [path stroke];
    }
    
    for (UIBezierPath *path in self.generatedPaths) {
        path.lineWidth = 2;
        [[UIColor redColor] setStroke];
        [path stroke];
    }
}

@end
