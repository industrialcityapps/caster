//
//  ICGestureRecognizer.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICGestureRecognizer.h"
#import "UIKit/UIGestureRecognizerSubclass.h"
#import <Accelerate/Accelerate.h>
#import "ICTouch.h"
#import "ICPath.h"

@interface ICGestureRecognizer ()

@property (nonatomic, strong) NSMutableArray *touchPaths;

@end

@implementation ICGestureRecognizer

@synthesize touchPaths = _CI_touchPaths;

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        [self reset];
    }
    return self;
}

- (NSArray *)bezierPaths
{
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[self.touchPaths count]];
    for (ICPath *path in self.touchPaths) {
        [paths addObject:[path bezierPath]];
    }
    return paths;
}

- (NSArray *)paths
{
    return [self.touchPaths copy];
}

#pragma mark - UIGestureRecognizer methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateBegan;
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        CGPoint previousPoint = [touch previousLocationInView:self.view];
        CGPoint currentPoint = [touch locationInView:self.view];
        
        // find the path for this touch, if any
        ICPath *path = nil;
        for (ICPath *currentPath in self.touchPaths) {
            if (CGPointEqualToPoint([(ICTouch *)[currentPath lastTouch] point], previousPoint)) {
                path = currentPath;
                break;
            }
        }
        
        // create a new path if no path was found for this point
        if (nil == path) {
            path = [[ICPath alloc] init];        
            [self.touchPaths addObject:path];
        }
        // add the new touch location to its path
        [path addTouch:[[ICTouch alloc] initWithPoint:currentPoint atTime:touch.timestamp]];
    }   
    
    self.state = UIGestureRecognizerStateChanged;
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateRecognized;
    [super touchesEnded:touches withEvent:event];
}

- (void)reset
{
    self.touchPaths = [NSMutableArray arrayWithCapacity:1];
    [super reset];
}

@end
