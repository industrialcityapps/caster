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
@property(nonatomic, readwrite, strong) UIBezierPath *reconstructedBezierPath;
@property(nonatomic, readwrite, strong) NSNumber *velocityMagnitude;
@property(nonatomic, readwrite, strong) NSNumber *xEnergy;
@property(nonatomic, readwrite, strong) NSNumber *yEnergy;

@end

@implementation ICPath

@synthesize touches = _IC_touches;
@synthesize fftXValues = _IC_fftXValues;
@synthesize fftYValues = _IC_fftYValues;
@synthesize reconstructedBezierPath = _IC_reconstructedBezierPath;
@synthesize velocityMagnitude = _IC_velocityMagnitude;
@synthesize xEnergy = _IC_xEnergy;
@synthesize yEnergy = _IC_yEnergy;

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
    NSTimeInterval stepInterval = 0.005;
    NSTimeInterval maxDuration = 10.0;
    
    NSTimeInterval startTime = [[(ICTouch *)[self.touches objectAtIndex:0] timestamp] doubleValue];
    NSTimeInterval endTime = MIN(startTime + maxDuration, [[(ICTouch *)[self.touches lastObject] timestamp] doubleValue]);
    NSUInteger numPositions = (endTime - startTime) / stepInterval;
    
    if (numPositions == 0) {
        return;
    }
    CGPoint *positions = (CGPoint *)malloc(numPositions * sizeof(CGPoint));

    NSUInteger touchIndex = 0;

    for (NSUInteger index = 0; index < numPositions; index++) {
        
        NSTimeInterval windowStart = startTime + index * stepInterval;
        
        while (touchIndex < [[self touches] count] - 1 && [[(ICTouch *)[self.touches objectAtIndex:touchIndex + 1] timestamp] doubleValue] <= windowStart) {
            touchIndex++;
        }
        
        ICTouch *touch = [[self touches] objectAtIndex:touchIndex];
        double x = [[touch x] doubleValue];
        double y = [[touch y] doubleValue];
        
        positions[index] = CGPointMake(x, y);
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
    
    float *x_sinusoid = (float *) malloc(sampleSize * sizeof(float));
    float *y_sinusoid = (float *) malloc(sampleSize * sizeof(float));
    float *inverse_x_sinusoid = (float *) malloc(sampleSize * sizeof(float));
    float *inverse_y_sinusoid = (float *) malloc(sampleSize * sizeof(float));
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
    
    //reverse the FFT
    vDSP_fft_zrip(setup, &A, stride, log2FFTSize, FFT_INVERSE);
    float scale = (float) 1.0 / (2 * sampleSize);
    vDSP_vsmul(A.realp, 1, &scale, A.realp, 1, bins);
    vDSP_vsmul(A.imagp, 1, &scale, A.imagp, 1, bins);
    vDSP_ztoc(&A, stride, (COMPLEX *)inverse_x_sinusoid, stride, bins);

    // Repeat for y axis
    vDSP_ctoz((COMPLEX *) y_sinusoid, stride, &A, stride, bins);
    vDSP_fft_zrip(setup, &A, stride, log2FFTSize, FFT_FORWARD);
    vDSP_zvabs(&A, stride, y_magnitudes, stride, bins);
    
    vDSP_fft_zrip(setup, &A, stride, log2FFTSize, FFT_INVERSE);
    vDSP_vsmul(A.realp, 1, &scale, A.realp, 1, bins);
    vDSP_vsmul(A.imagp, 1, &scale, A.imagp, 1, bins);
    vDSP_ztoc(&A, stride, (COMPLEX *)inverse_y_sinusoid, stride, bins);
    
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
    
    //rebuild a sequence of points as a bezier path
    UIBezierPath *bzPath = [[UIBezierPath alloc] init];
    for (NSUInteger index = 0; index < sampleSize; index++) {
        CGPoint point = CGPointMake(inverse_x_sinusoid[index], inverse_y_sinusoid[index]);
        if ([bzPath isEmpty]) {
            [bzPath moveToPoint:point];
        }
        else {
            [bzPath addLineToPoint:point];
        }
    }
    //self.reconstructedBezierPath = bzPath;
    
    vDSP_destroy_fftsetup(setup);
    free(x_magnitudes);
    free(y_magnitudes);
    free(x_sinusoid);
    free(y_sinusoid);
    free(inverse_x_sinusoid);
    free(inverse_y_sinusoid);
    free(A.realp);
    free(A.imagp);
    
    //energy
    float xEnergy = 0;
    for (uint32_t index = 2; index < [self.fftXValues count]; index++) {
        xEnergy += [[self.fftXValues objectAtIndex:index] floatValue];
    }
    self.xEnergy = [NSNumber numberWithFloat:xEnergy];
    
    float yEnergy = 0;
    for (uint32_t index = 2; index < [self.fftYValues count]; index++) {
        yEnergy += [[self.fftYValues objectAtIndex:index] floatValue];
    }
    self.yEnergy = [NSNumber numberWithFloat:yEnergy];
    
    //velocity
    float xVelocity = 0;
    float yVelocity = 0;
    float x = positions[0].x;
    float y = positions[0].y;
    for (int32_t index = 0; index < numPositions; index++) {
        CGPoint point = positions[index];
        xVelocity += (point.x - x);
        x = point.x;
        yVelocity += (point.y - y);
        y = point.y;
    }
    self.velocityMagnitude = [NSNumber numberWithFloat:sqrtf(powf(xVelocity, 2) + powf(yVelocity, 2))];
    
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
