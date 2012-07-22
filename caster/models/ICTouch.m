//
//  ICTouch.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICTouch.h"

@implementation ICTouch

@synthesize x = _IC_x;
@synthesize y = _IC_y;
@synthesize timestamp = _IC_timestamp;

- (id)initWithPoint:(CGPoint)point atTime:(NSTimeInterval)interval
{
    self = [self init];
    if (self) {
        self.x = [NSNumber numberWithInteger:point.x];
        self.y = [NSNumber numberWithInteger:point.y];
        self.timestamp = [NSNumber numberWithInteger:interval];
    }
    return self;
}

- (CGPoint)point
{
    return CGPointMake([self.x integerValue], [self.y integerValue]);
}

@end
