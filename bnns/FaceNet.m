//
//  FaceNet.m
//  bnns
//
//  Created by Nate Parrott on 1/11/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "FaceNet.h"
@import Accelerate;
#import "UIImage+PixelData.h"
#import "UIImage+Resize.h"
#import "UIImage+MainFace.h"

// https://github.com/nate-parrott/juypter-notebooks/blob/master/face-attrib-detect.ipynb

static BNNSActivation FNActivationNone = {.function = BNNSActivationFunctionIdentity};
static BNNSActivation FNActivationRelu = {.function = BNNSActivationFunctionRectifiedLinear};
static BNNSActivation FNActivationSigmoid = {.function = BNNSActivationFunctionSigmoid};

typedef struct {
    NSInteger height, width, depth;
} FNImageSize;

FNImageSize FNImageSizeMake(NSInteger height, NSInteger width, NSInteger depth) {
    FNImageSize size = {height, width, depth};
    return size;
}

float* FNTranspose2d(NSInteger rows, NSInteger cols, float* input) {
    float *output = malloc(cols * rows * sizeof(float));
    vDSP_mtrans(input, 1, output, 1, cols, rows);
    free(input);
    return output;
}

BNNSImageStackDescriptor FNImageSizeToStackDescriptor(FNImageSize size) {
    BNNSImageStackDescriptor desc;
    desc.width = size.width;
    desc.height = size.height;
    desc.channels = size.depth;
    desc.row_stride = size.width;
    desc.image_stride = size.height * size.width;
    desc.data_type = BNNSDataTypeFloat32;
    return desc;
}

BNNSVectorDescriptor FNVectorLengthToDescriptor(NSInteger length) {
    BNNSVectorDescriptor desc;
    desc.data_type = BNNSDataTypeFloat32;
    desc.size = length;
    return desc;
}

@interface FNLayer : NSObject {
    BNNSFilter _filter;
}

@property (nonatomic) size_t outputDataSize;

@end

@implementation FNLayer

- (float *)loadWeightFile:(NSString *)name expectedSize:(NSInteger)size {
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"weight"]];
    NSAssert(data.length/4 == size, @"Incorrect size for weight %@ [%@ instead of %@]", name, @(data.length/4), @(size));
    float *bytes = malloc(data.length);
    memcpy(bytes, data.bytes, data.length);
    // TODO: free this later
    return bytes;
}

- (void)processInput:(float *)input output:(float *)output {
    BNNSFilterApply(_filter, input, output);
}

@end

@interface FNFullyConnectedLayer : FNLayer

@end

@implementation FNFullyConnectedLayer

- (instancetype)initFullyConnectedWithInputSize:(NSInteger)inSize outputSize:(NSInteger)outSize activation:(BNNSActivation)activation weightName:(NSString *)weightName biasName:(NSString *)biasName {
    self = [super init];
    
    BNNSFullyConnectedLayerParameters params;
    params.activation = activation;
    params.in_size = inSize;
    params.out_size = outSize;
    params.weights.data_type = BNNSDataTypeFloat32;
    params.weights.data = [self loadWeightFile:weightName expectedSize:inSize * outSize];
    params.bias.data_type = BNNSDataTypeFloat32;
    params.bias.data = [self loadWeightFile:biasName expectedSize:outSize];
    
    BNNSVectorDescriptor inputDesc = FNVectorLengthToDescriptor(inSize);
    BNNSVectorDescriptor outputDesc = FNVectorLengthToDescriptor(outSize);
    
    _filter = BNNSFilterCreateFullyConnectedLayer(&inputDesc, &outputDesc, &params, nil);
    NSAssert(_filter, @"Failed to create filter");
    
    self.outputDataSize = outSize * sizeof(float);
    
    return self;
}

@end


@interface FNConvolutionalLayer : FNLayer

@end

@implementation FNConvolutionalLayer

- (instancetype)initConvolutionalWithFilterSize:(NSInteger)filterSize weightName:(NSString *)weightName biasName:(NSString *)biasName inputSize:(FNImageSize)inputSize outputSize:(FNImageSize)outputSize activation:(BNNSActivation)activation {
    self = [super init];
    
    BNNSConvolutionLayerParameters params;
    params.activation = activation;
    params.in_channels = inputSize.depth;
    params.out_channels = outputSize.depth;
    params.k_width = filterSize;
    params.k_height = filterSize;
    params.x_padding = filterSize/2;
    params.y_padding = filterSize/2;
    params.x_stride = 1;
    params.y_stride = 1;
    params.weights.data_type = BNNSDataTypeFloat32;
    params.weights.data = [self loadWeightFile:weightName expectedSize:filterSize*filterSize*inputSize.depth*outputSize.depth];
    params.bias.data_type = BNNSDataTypeFloat32;
    params.bias.data = [self loadWeightFile:biasName expectedSize:outputSize.depth];
    
    BNNSImageStackDescriptor inputImageDesc = FNImageSizeToStackDescriptor(inputSize);
    BNNSImageStackDescriptor outputImageDesc = FNImageSizeToStackDescriptor(outputSize);
    BNNSFilterParameters filterParams;
    memset(&filterParams, 0, sizeof(filterParams));
    
    _filter = BNNSFilterCreateConvolutionLayer(&inputImageDesc, &outputImageDesc, &params, &filterParams);
    NSAssert(_filter, @"Failed to create filter");
    
    self.outputDataSize = outputSize.width * outputSize.height * outputSize.depth * sizeof(float);
    
    return self;
}

@end



@interface FNPoolingLayer : FNLayer

@end

@implementation FNPoolingLayer

- (instancetype)initWithImageSize:(FNImageSize)inputSize poolingType:(BNNSPoolingFunction)poolingType kernelSizeAndStride:(NSInteger)ksize {
    
    BNNSImageStackDescriptor inputImageDesc = FNImageSizeToStackDescriptor(inputSize);
    FNImageSize outputSize = inputSize;
    outputSize.width /= ksize;
    outputSize.height /= ksize;
    BNNSImageStackDescriptor outputImageDesc = FNImageSizeToStackDescriptor(outputSize);
    
    BNNSPoolingLayerParameters params;
    memset(&params, 0, sizeof(params));
    params.x_stride = ksize;
    params.y_stride = ksize;
    params.k_width = ksize;
    params.k_height = ksize;
    params.in_channels = inputSize.depth;
    params.out_channels = outputSize.depth;
    params.pooling_function = poolingType;
    
    _filter = BNNSFilterCreatePoolingLayer(&inputImageDesc, &outputImageDesc, &params, nil);
    NSAssert(_filter, @"Failed to create filter");
    
    return self;
}

@end



@interface FNBatchNormalizationLayer : FNLayer {
    float *_data;
    FNImageSize _size;
}

@end

@implementation FNBatchNormalizationLayer

- (instancetype)initWithDataName:(NSString *)name imageSize:(FNImageSize)size {
    self = [super init];
    _size = size;
    // data file is three concatenated lists of floats: mean, variance, and bias (per-channel)
    _data = [self loadWeightFile:name expectedSize:size.depth * 3];
    return self;
}

- (void)dealloc {
    free(_data);
}

- (void)processInput:(float *)input output:(float *)output {
    float epsilon = 0.001;
    
    float *means = _data;
    float *variances = _data + _size.width * _size.height;
    float *betas = _data + _size.width *_size.height * 2;
    
    NSInteger channelSize = _size.width * _size.height;
    
    for (NSInteger channel=0; channel<_size.depth; channel++) {
        float mean = means[channel];
        float mult = 1.0 / (powf(variances[channel], 2) + epsilon);
        float beta = betas[channel];
        
        NSInteger from = channelSize * channel;
        NSInteger until = channelSize * (channel + 1);
        
        for (NSInteger i=from; i<until; i++) {
            output[i] = (input[i] - mean) * mult + beta;
        }
    }
}

@end


typedef enum {
    FNTransposeModeInterleavedImageToStack,
    FNTransposeModeImageStackToInterleaved
} FNTransposeMode;

@interface FNTransposeLayer : FNLayer

@property (nonatomic) FNTransposeMode mode;
@property (nonatomic) FNImageSize size;

@end

@implementation FNTransposeLayer

- (instancetype)initWithMode:(FNTransposeMode)mode imageSize:(FNImageSize)size {
    self = [super init];
    self.mode = mode;
    self.size = size;
    return self;
}

- (void)processInput:(float *)input output:(float *)output {
    if (self.mode == FNTransposeModeInterleavedImageToStack) {
        for (NSInteger channel=0; channel<_size.depth; channel++) {
            for (NSInteger row=0; row<_size.height; row++) {
                for (NSInteger col=0; col<_size.width; col++) {
                    output[channel * _size.width * _size.height + row * _size.width + col] = input[row*_size.width*_size.depth + col*_size.depth + channel];
                }
            }
        }
    } else if (self.mode == FNTransposeModeImageStackToInterleaved) {
        for (NSInteger channel=0; channel<_size.depth; channel++) {
            for (NSInteger row=0; row<_size.height; row++) {
                for (NSInteger col=0; col<_size.width; col++) {
                    output[row*_size.width*_size.depth + col*_size.depth + channel] = input[channel * _size.width * _size.height + row * _size.width + col];
                }
            }
        }
    }
}

@end


@interface FNPerImageStandardizationLayer : FNLayer

@property (nonatomic) FNImageSize size;

@end

@implementation FNPerImageStandardizationLayer

- (instancetype)initWithSize:(FNImageSize)size {
    self = [super init];
    self.size = size;
    return self;
}

- (void)processInput:(float *)input output:(float *)output {
    NSInteger nElements = self.size.width * self.size.height * self.size.depth;
    float mean;
    vDSP_meanv(input, 1, &mean, nElements);
    // sqrt(sum(A[n]**2, 0 <= n < N) / N - m**2);
    double stddev = 0;
    for (NSInteger i=0; i<nElements; i++) {
        stddev += pow(input[i], 2);
    }
    stddev = sqrt(stddev / nElements - mean * mean);
    float adjustedStddev = MAX(stddev, 1.0 / sqrt(nElements));
    for (NSInteger i=0; i<nElements; i++) {
        output[i] = (input[i] - mean) / adjustedStddev;
    }
}

@end



@interface FNLayerChain : NSObject {
    float *_buffer1, *_buffer2;
}

@property (nonatomic) NSArray<FNLayer *> *layers;

@end


@implementation FNLayerChain

- (instancetype)initWithLayers:(NSArray<FNLayer *> *)layers inputCount:(NSInteger)count {
    self = [super init];
    self.layers = layers;
    
    size_t bufferSize = count * sizeof(float);
    for (FNLayer *layer in layers) {
        bufferSize = MAX(bufferSize, layer.outputDataSize);
    }
    _buffer1 = malloc(bufferSize);
    _buffer2 = malloc(bufferSize);
    // TODO: free these later
    
    return self;
}

- (float *)inputBuffer {
    return _buffer1;
}

- (float *)run {
    float *buffer = [self inputBuffer];
    for (FNLayer *layer in self.layers) {
        float *nextBuffer = (buffer == _buffer1) ? _buffer2 : _buffer1;
        [layer processInput:buffer output:nextBuffer];
        buffer = nextBuffer;
    }
    return buffer;
}

@end




@interface FaceNet ()

@property (nonatomic) FNLayerChain *chain;

@end

@implementation FaceNet

- (instancetype)init {
    self = [super init];
    
    /*
     image = tf.image.resize_bilinear(image, [64, 64])
     for i, size in enumerate([16, 32, 64, 64]):
     key = 'conv' + str(i)
     image = create_conv(image, size, patch_size=5, key=key)
     image = create_avg_pool(image)
     # now we have a 4x4x64 image:
     image = create_dropout(image)
     image = create_fc(flatten_tensor(image), 256, key='fc1')
     image = create_fc(image, 256, key='fc2')
     return create_fc(image, len(keys), relu=False, key='fc3')
     */
    
    FNTransposeLayer *transpose0 = [[FNTransposeLayer alloc] initWithMode:FNTransposeModeInterleavedImageToStack imageSize:FNImageSizeMake(64, 64, 3)];
    
    FNPerImageStandardizationLayer *standardization = [[FNPerImageStandardizationLayer alloc] initWithSize:FNImageSizeMake(64, 64, 3)];
    
    FNConvolutionalLayer *conv0 = [[FNConvolutionalLayer alloc] initConvolutionalWithFilterSize:5 weightName:@"conv0.w.5_5_3_16" biasName:@"conv0.b.16" inputSize:FNImageSizeMake(64,64,3) outputSize:FNImageSizeMake(64,64,16) activation:FNActivationRelu];
    FNPoolingLayer *pool0 = [[FNPoolingLayer alloc] initWithImageSize:FNImageSizeMake(64, 64, 16) poolingType:BNNSPoolingFunctionAverage kernelSizeAndStride:2];
    
    FNConvolutionalLayer *conv1 = [[FNConvolutionalLayer alloc] initConvolutionalWithFilterSize:5 weightName:@"conv1.w.5_5_16_32" biasName:@"conv1.b.32" inputSize:FNImageSizeMake(32,32,16) outputSize:FNImageSizeMake(32,32,32) activation:FNActivationRelu];
    FNPoolingLayer *pool1 = [[FNPoolingLayer alloc] initWithImageSize:FNImageSizeMake(32, 32, 32) poolingType:BNNSPoolingFunctionAverage kernelSizeAndStride:2];
    
    FNConvolutionalLayer *conv2 = [[FNConvolutionalLayer alloc] initConvolutionalWithFilterSize:5 weightName:@"conv2.w.5_5_32_64" biasName:@"conv2.b.64" inputSize:FNImageSizeMake(16,16,32) outputSize:FNImageSizeMake(16,16,64) activation:FNActivationRelu];
    FNPoolingLayer *pool2 = [[FNPoolingLayer alloc] initWithImageSize:FNImageSizeMake(16, 16, 64) poolingType:BNNSPoolingFunctionAverage kernelSizeAndStride:2];
    
    FNConvolutionalLayer *conv3 = [[FNConvolutionalLayer alloc] initConvolutionalWithFilterSize:5 weightName:@"conv3.w.5_5_64_64" biasName:@"conv3.b.64" inputSize:FNImageSizeMake(8,8,64) outputSize:FNImageSizeMake(8,8,64) activation:FNActivationRelu];
    FNPoolingLayer *pool3 = [[FNPoolingLayer alloc] initWithImageSize:FNImageSizeMake(8, 8, 64) poolingType:BNNSPoolingFunctionAverage kernelSizeAndStride:2];
    
    FNTransposeLayer *transpose1 = [[FNTransposeLayer alloc] initWithMode:FNTransposeModeImageStackToInterleaved imageSize:FNImageSizeMake(4, 4, 64)];
    
    FNFullyConnectedLayer *fc1 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:4*4*64 outputSize:256 activation:FNActivationRelu weightName:@"fc1.w.1024_256" biasName:@"fc1.b.256"];
    
    FNFullyConnectedLayer *fc2 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:256 outputSize:256 activation:FNActivationRelu weightName:@"fc2.w.256_256" biasName:@"fc2.b.256"];
    
    FNFullyConnectedLayer *fc3 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:256 outputSize:40 activation:FNActivationSigmoid weightName:@"fc3.w.256_40" biasName:@"fc3.b.40"];
    
    FNLayerChain *chain = [[FNLayerChain alloc] initWithLayers:@[transpose0, standardization, conv0, pool0, conv1, pool1, conv2, pool2, conv3, pool3, transpose1, fc1, fc2, fc3] inputCount:64 * 64 * 3];
    
    self.chain = chain;
    
    return self;
}

- (UIImage *)preprocessImage:(UIImage *)face {
    // TODO: crop so face fill 0.65 of width and image is 160 x 192
    
    UIGraphicsBeginImageContext(CGSizeMake(64, 64));
    [face drawInRect:CGRectMake(0, 0, 64, 64)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (void)xorTest {
    NSLog(@"XOR test:");
    FNFullyConnectedLayer *fc1 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:2 outputSize:16 activation:FNActivationRelu weightName:@"xor.fc1.w" biasName:@"xor.fc1.b"];
    FNFullyConnectedLayer *fc2 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:16 outputSize:16 activation:FNActivationRelu weightName:@"xor.fc2.w" biasName:@"xor.fc2.b"];
    FNFullyConnectedLayer *fc3 = [[FNFullyConnectedLayer alloc]initFullyConnectedWithInputSize:16 outputSize:1 activation:FNActivationRelu weightName:@"xor.fc3.w" biasName:@"xor.fc3.b"];
    FNLayerChain *chain = [[FNLayerChain alloc] initWithLayers:@[fc1, fc2, fc3] inputCount:2];
    
    [chain inputBuffer][0] = 0;
    [chain inputBuffer][1] = 1;
    float out = [chain run][0];
    NSLog(@"Got %f, expected 1", out);
    
    [chain inputBuffer][0] = 0;
    [chain inputBuffer][1] = 0;
    out = [chain run][0];
    NSLog(@"Got %f, expected 0", out);
    
    [chain inputBuffer][0] = 1;
    [chain inputBuffer][1] = 0;
    out = [chain run][0];
    NSLog(@"Got %f, expected 1", out);
    
    [chain inputBuffer][0] = 1;
    [chain inputBuffer][1] = 1;
    out = [chain run][0];
    NSLog(@"Got %f, expected 0", out);
}

- (void)convTest {
    NSLog(@"Conv test:");
#define RED 1,0,0
#define GREEN 0,1,0
#define BLUE 0,0,1
    float image1[27] = {
        // [[b,g,b], [r,r,g], [g,g,b]]
        BLUE, GREEN, BLUE,   RED, RED, GREEN,   GREEN, GREEN, BLUE
    };
    float image2[27] = {
        // [[r,r,r], [g,g,b], [g,b,r]]
        RED, RED, RED,   GREEN, GREEN, BLUE,   GREEN, BLUE, RED
    };
    float image3[27] = {
        // [[r,r,g], [g,g,r], [r,g,g]]
        RED, RED, GREEN,   GREEN, GREEN, RED,   RED, GREEN, GREEN
    };
    
    FNImageSize size = {3, 3, 3};
    FNImageSize convolvedSize = {3, 3, 5};
    
    FNTransposeLayer *layer1 = [[FNTransposeLayer alloc] initWithMode:FNTransposeModeInterleavedImageToStack imageSize:size];
    FNConvolutionalLayer *conv2 = [[FNConvolutionalLayer alloc] initConvolutionalWithFilterSize:3 weightName:@"conv.conv1.w" biasName:@"conv.conv1.b" inputSize:size outputSize:convolvedSize activation:FNActivationRelu];
    FNTransposeLayer *layer3 = [[FNTransposeLayer alloc] initWithMode:FNTransposeModeImageStackToInterleaved imageSize:convolvedSize];
    FNFullyConnectedLayer *fc4 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:45 outputSize:32 activation:FNActivationRelu weightName:@"conv.fc2.w" biasName:@"conv.fc2.b"];
    FNFullyConnectedLayer *fc5 = [[FNFullyConnectedLayer alloc] initFullyConnectedWithInputSize:32 outputSize:3 activation:FNActivationRelu weightName:@"conv.fc3.w" biasName:@"conv.fc3.b"];
    
    FNLayerChain *chain = [[FNLayerChain alloc] initWithLayers:@[layer1, conv2, layer3, fc4, fc5] inputCount:9 * 3];
    
    memcpy([chain inputBuffer], image1, 9 * 3 * sizeof(float));
    float *out = [chain run];
    NSLog(@"Got [%f,%f,%f], expected [1,0,0]", out[0], out[1], out[2]);
    
    memcpy([chain inputBuffer], image2, 9 * 3 * sizeof(float));
    out = [chain run];
    NSLog(@"Got [%f,%f,%f], expected [0,1,0]", out[0], out[1], out[2]);
    
    memcpy([chain inputBuffer], image3, 9 * 3 * sizeof(float));
    out = [chain run];
    NSLog(@"Got [%f,%f,%f], expected [0,0,1]", out[0], out[1], out[2]);
}

- (void)faceTest {
    UIImage *face = [[UIImage imageNamed:@"congress"] fn_mainFace];
    NSDictionary *d = [self attributesForFace:face];
    for (NSString *key in d) {
        NSLog(@"%@: %@", key, d[key]);
    }
}

- (NSDictionary<NSString *, NSNumber *> *)attributesForFace:(UIImage *)image {
    NSArray *attrs = [@"5_o_Clock_Shadow Arched_Eyebrows Attractive Bags_Under_Eyes Bald Bangs Big_Lips Big_Nose Black_Hair Blond_Hair Blurry Brown_Hair Bushy_Eyebrows Chubby Double_Chin Eyeglasses Goatee Gray_Hair Heavy_Makeup High_Cheekbones Male Mouth_Slightly_Open Mustache Narrow_Eyes No_Beard Oval_Face Pale_Skin Pointy_Nose Receding_Hairline Rosy_Cheeks Sideburns Smiling Straight_Hair Wavy_Hair Wearing_Earrings Wearing_Hat Wearing_Lipstick Wearing_Necklace Wearing_Necktie Young" componentsSeparatedByString:@" "];
    
    float *imageArray = [[image atSize:CGSizeMake(64, 64)] floatArray];
    memcpy([self.chain inputBuffer], imageArray, sizeof(float) * 64 * 64 * 3);
    
    float *results = [self.chain run];
    
    free(imageArray);
    
    NSMutableDictionary *resultsDict = [NSMutableDictionary new];
    for (NSInteger i=0; i<40; i++) {
        resultsDict[attrs[i]] = @(results[i]);
    }
    return resultsDict;
}

+ (FaceNet *)shared {
    static FaceNet *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [FaceNet new];
    });
    return shared;
}

@end
