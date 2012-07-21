//
//  ICPathView.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICPathView.h"

@implementation ICPathView

@synthesize paths = _CI_paths;

- (void)setPaths:(NSArray *)paths
{
    _CI_paths = paths;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] setStroke];
    
    for (UIBezierPath *path in self.paths) {
        path.lineWidth = 5;
        [path stroke];
    }
}

@end
