#import <Kiwi/Kiwi.h>
#import <Accelerate/Accelerate.h>
#import <math.h>

void
Compare(float *original, float *computed, long length)
{
    int             i;
    float           error = original[0] - computed[0];
    float           max = error;
    float           min = error;
    float           mean = 0.0;
    float           sd_radicand = 0.0;
    
    for (i = 0; i < length; i++) {
        error = original[i] - computed[i];
        /* printf("%f %f %f\n", original[i], computed[i], error); */
        max = (max < error) ? error : max;
        min = (min > error) ? error : min;
        mean += (error / length);
        sd_radicand += ((error * error) / (float) length);
    }
    
    printf("Max error: %f  Min error: %f  Mean: %f  Std Dev: %f\n",
           max, min, mean, sqrt(sd_radicand));
}

SPEC_BEGIN(FFTSpec)

describe(@"FFT", ^{
    it(@"should work", ^{
        UInt32 sampleSize = 128;        
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
            NSLog(@"REAL %d = %f", index, real_sinusoid[index]);
        }
        
        // setup FFT
        FFTSetup setup;
        setup = vDSP_create_fftsetup(log2FFTSize, kFFTRadix2);
        
        [[theValue(setup) shouldNot] equal:theValue(0)]; //setup will be 0 if Accelerate fails to allocate the precalculated data
        
        // Pack the input values
                
        [[theValue(A.realp) shouldNot] equal:theValue(NULL)];
        [[theValue(A.imagp) shouldNot] equal:theValue(NULL)];
        
        /* Look at the real signal as an interleaved complex vector  by
         * casting it.  Then call the transformation function vDSP_ctoz to
         * get a split complex vector, which for a real signal, divides into
         * an even-odd configuration. */
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
        
        for(int32_t index = 0; index < bins; index++)
        {
            NSLog(@"FFT result %d = (%f, %f) magnitude = %f", index, A.realp[index], A.imagp[index], magnitudes[index]);
        }
        
        vDSP_destroy_fftsetup(setup);
        free(real_sinusoid);
        free(magnitudes);
        free(A.realp);
        free(A.imagp);
    });    
});

SPEC_END