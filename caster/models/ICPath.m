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
@property(nonatomic, strong) NSMutableArray *fftValues;

@end

@implementation ICPath

@synthesize touches = _IC_touches;
@synthesize fftValues = _IC_fftValues;

- (id)init
{
    self = [super init];
    if (self) {
        self.touches = [NSMutableArray array];
        self.fftValues = [NSMutableArray array];
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
    NSTimeInterval stepInterval = 0.1;
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
    
    // given a periodic sample
    float *real_sinusoid = (float *) malloc(sampleSize * sizeof(float));;
    for (int32_t index = 0; index < sampleSize; index++) {
        real_sinusoid[index] = sinf(M_PI_4 * index);
    }
    
    // setup FFT
    FFTSetup setup;
    setup = vDSP_create_fftsetup(log2FFTSize, kFFTRadix2);
        
    // Pack the input values
    vDSP_ctoz((COMPLEX *) real_sinusoid, 2, &A, 1, bins);
    
    // Perform the FFT
    vDSP_fft_zrip(setup, &A, stride, log2FFTSize, FFT_FORWARD);
    
    // get and scale the magnitudes of the complex result
    float *magnitudes = (float *) malloc(bins * sizeof(float));
    vDSP_zvabs(&A, stride, magnitudes, stride, bins);
    float *scaleFactors = malloc(bins * sizeof(float));
    for(int32_t index = 0; index < bins; index++)
    {
        scaleFactors[index] = bins;
    }
    vDSP_vsdiv(magnitudes, 1, scaleFactors, magnitudes, 1, bins);
    free(scaleFactors);
    
    [self.fftValues removeAllObjects];
    for (NSUInteger index = 0; index < bins; index++) {
        [self.fftValues addObject:[NSNumber numberWithFloat:magnitudes[index]]];
    }
    
    vDSP_destroy_fftsetup(setup);
    free(real_sinusoid);
    free(magnitudes);
    free(A.realp);
    free(A.imagp);
    
    free(positions);
}

@end
