//
//  ICPath.h
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@class ICTouch;

@interface ICPath : NSObject <CPTPlotDataSource>

@property(nonatomic, readonly, strong) UIBezierPath *reconstructedBezierPath;
@property(nonatomic, readonly, strong) NSNumber *velocityMagnitude;
@property(nonatomic, readonly, strong) NSNumber *xEnergy;
@property(nonatomic, readonly, strong) NSNumber *yEnergy;

- (id)initWithTouches:(NSArray *)touches;

- (void)addTouch:(ICTouch *)touch;
- (ICTouch *)lastTouch;
- (UIBezierPath *)bezierPath;
- (NSArray *)allTouches;

- (void)computeAttributes;

@end
