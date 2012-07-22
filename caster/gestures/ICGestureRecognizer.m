//
//  ICGestureRecognizer.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICGestureRecognizer.h"
#import "UIKit/UIGestureRecognizerSubclass.h"

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

- (NSArray *)paths
{
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[self.touchPaths count]];
    for (NSArray *path in self.touchPaths) {
        UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
        for (NSString *pointString in path) {
            CGPoint point = CGPointFromString(pointString);
            if ([bezierPath isEmpty]) {
                [bezierPath moveToPoint:point];
            }
            else {
                [bezierPath addLineToPoint:point];
            }
        }
        [paths addObject:bezierPath];
    }
    return paths;
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
        NSString *previousPointString = NSStringFromCGPoint([touch previousLocationInView:self.view]);
        NSString *currentPointString = NSStringFromCGPoint([touch locationInView:self.view]);
        
        // find the path for this touch, if any
        NSMutableArray *path = nil;
        for (NSMutableArray *currentPath in self.touchPaths) {
            if ([[currentPath lastObject] isEqualToString:previousPointString]) {
                path = currentPath;
                break;
            }
        }
        
        // create a new path if no path was found for this point
        if (nil == path) {
            path = [NSMutableArray array];        
            [path addObject:currentPointString];
            [self.touchPaths addObject:path];
        }
        else {
            // add the new touch location to its path
            [path addObject:currentPointString];
        }
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
