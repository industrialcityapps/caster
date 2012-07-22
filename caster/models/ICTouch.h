//
//  ICTouch.h
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICTouch : NSObject

@property(nonatomic, strong) NSNumber *x;
@property(nonatomic, strong) NSNumber *y;
@property(nonatomic, strong) NSNumber *timestamp;
@property(nonatomic, weak) UITouch *touch;

- (id)initWithPoint:(CGPoint)point atTime:(NSTimeInterval)interval;
- (CGPoint)point;

@end
