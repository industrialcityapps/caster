//
//  ICPath.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICPath.h"
#import "ICTouch.h"
#import <Accelerate/Accelerate.h>

@interface ICPath ()

@property(nonatomic, strong) NSMutableArray *touches;
@property(nonatomic, strong) NSMutableArray *fftXValues;
@property(nonatomic, strong) NSMutableArray *fftYValues;

@end

@implementation ICPath

@synthesize touches = _IC_touches;
@synthesize fftXValues = _IC_fftXValues;
@synthesize fftYValues = _IC_fftYValues;

- (id)init
{
    self = [super init];
    if (self) {
        self.touches = [NSMutableArray array];
        self.fftXValues = [NSMutableArray array];
        self.fftYValues = [NSMutableArray array];
    }
    return self;
}

- (id)initWithTouches:(NSArray *)touches
{
    self = [self init];
    if (self) {
        [self.touches addObjectsFromArray:touches];
    }
    return self;
}

- (void)addTouch:(ICTouch *)touch
{
    [self.touches addObject:touch];
}

- (ICTouch *)lastTouch
{
    return [self.touches lastObject];
}

- (UIBezierPath *)bezierPath
{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    for (ICTouch *touch in self.touches) {
        if ([bezierPath isEmpty]) {
            [bezierPath moveToPoint:[touch point]];
        }
        else {
            [bezierPath addLineToPoint:[touch point]];
        }
    }
    return bezierPath;
}

- (NSArray *)allTouches
{
    return self.touches;
}

- (void)computeAttributes
{
    NSTimeInterval stepInterval = 0.05;
    NSTimeInterval maxDuration = 10.0;
    
    NSTimeInterval startTime = [[(ICTouch *)[self.touches objectAtIndex:0] timestamp] doubleValue];
    NSTimeInterval endTime = MIN(startTime + maxDuration, [[(ICTouch *)[self.touches lastObject] timestamp] doubleValue]);
    NSUInteger numPositions = (endTime - startTime) / stepInterval;
    
    if (numPositions == 0) {
        return;
    }
    CGPoint *positions = (CGPoint *)malloc(numPositions * sizeof(CGPoint));
    
    NSTimeInterval currentTime = startTime;
    NSUInteger currentTouchIndex = 0;
    for (NSUInteger index = 0; index < numPositions; index++) {
        ICTouch *touch = [self.touches objectAtIndex:currentTouchIndex];
        if ([[touch timestamp] doubleValue] <= currentTime) {
            positions[index] = [touch point];
            currentTouchIndex++;
        }
        else if (currentTouchIndex < [self.touches count] - 1) {
            ICTouch *nextTouch = [self.touches objectAtIndex:currentTouchIndex + 1];
            CGPoint nextPoint = [nextTouch point];
            NSTimeInterval nextTime = [[nextTouch timestamp] doubleValue];
            NSUInteger nextIndex = (nextTime - currentTime) / stepInterval + index;
            positions[index] = CGPointMake(
                                           [touch.x integerValue] + (nextPoint.x - [touch.x integerValue])/(nextIndex - index), 
                                           [touch.y integerValue] + (nextPoint.y - [touch.y integerValue])/(nextIndex - index)
                                           );
        }
        currentTime += stepInterval;
    }
    
    UInt32 sampleSize = numPositions;        
    UInt32 bins = sampleSize / 2;
    UInt32 log2FFTSize = log2l(sampleSize);
    UInt32 stride = 1;
    
    COMPLEX_SPLIT A;
    A.realp = (float *) malloc(bins * sizeof(float));
    A.imagp = (float *) malloc(bins * sizeof(float));
    
    float *x_magnitudes = (float *) malloc(bins * sizeof(float));
    float *y_magnitudes = (float *) malloc(bins * sizeof(float));
    
    // setup FFT
    FFTSetup setup;
    setup = vDSP_create_fftsetup(log2FFTSize, kFFTRadix2);
    
    float *x_sinusoid = (float *) malloc(sampleSize * sizeof(float));;
    float *y_sinusoid = (float *) malloc(sampleSize * sizeof(float));;
    for (int32_t index = 0; index < sampleSize; index++) {
        CGPoint point = (CGPoint)positions[index];
        x_sinusoid[index] = point.x;
        y_sinusoid[index] = point.y;
    }
    
    // Pack the input values
    vDSP_ctoz((COMPLEX *) x_sinusoid, stride, &A, stride, bins);
    
    // Perform the FFT
    vDSP_fft_zrip(setup, &A, stride, log2FFTSize, FFT_FORWARD);
    
    vDSP_zvabs(&A, stride, x_magnitudes, stride, bins);

    // Repeat for y axis
    vDSP_ctoz((COMPLEX *) y_sinusoid, stride, &A, stride, bins);
    vDSP_fft_zrip(setup, &A, stride, log2FFTSize, FFT_FORWARD);
    vDSP_zvabs(&A, stride, y_magnitudes, stride, bins);
    
    // get and scale the magnitudes of the complex result
    float *scaleFactors = malloc(bins * sizeof(float));
    for(int32_t index = 0; index < bins; index++)
    {
        scaleFactors[index] = bins;
    }
    
    vDSP_vsdiv(x_magnitudes, stride, scaleFactors, x_magnitudes, stride, bins);
    vDSP_vsdiv(y_magnitudes, stride, scaleFactors, y_magnitudes, stride, bins);
    free(scaleFactors);
    
    [self.fftXValues removeAllObjects];
    [self.fftYValues removeAllObjects];
    for (NSUInteger index = 0; index < bins; index++) {
        [self.fftXValues addObject:[NSNumber numberWithFloat:x_magnitudes[index]]];
        [self.fftYValues addObject:[NSNumber numberWithFloat:y_magnitudes[index]]];
    }
    
    vDSP_destroy_fftsetup(setup);
    free(x_magnitudes);
    free(y_magnitudes);
    free(x_sinusoid);
    free(y_sinusoid);
    free(A.realp);
    free(A.imagp);
    
    free(positions);
}

#pragma mark - CPTPlotDataSource methods

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [self.fftXValues count];
}

- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    if ([plot.name isEqualToString:@"Y"]) {
        return [[self.fftYValues objectAtIndex:index] doubleValue];
    }
    return [[self.fftXValues objectAtIndex:index] doubleValue];
}

@end
