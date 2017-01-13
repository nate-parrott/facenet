//
//  FNCameraView.m
//  bnns
//
//  Created by Nate Parrott on 1/13/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "FNCameraView.h"
@import AVFoundation;

@interface FNCameraView () <AVCaptureMetadataOutputObjectsDelegate> {
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_camera;
    AVCaptureMetadataOutput *_metadataOutput;
    AVCaptureVideoPreviewLayer *_previewLayer;
}

@property (nonatomic) BOOL capturing;
@property (nonatomic) NSArray<AVMetadataFaceObject *> *faces;
@property (nonatomic) NSArray *faceViews;

@end

@implementation FNCameraView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    self.capturing = !!newWindow;
    
    // UITapGestureRecognizer *testTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(test:)];
}

-(void)setCapturing:(BOOL)capturing {
    if (capturing==_capturing) return;
    
    _capturing = capturing;
    if (!_captureSession) {
        // setup:
        
        _captureSession = [[AVCaptureSession alloc] init];
        _camera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
        if ([_camera lockForConfiguration:nil]) {
            if ([_camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [_camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            [_camera unlockForConfiguration];
        }
        AVCaptureDeviceInput* input = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:nil];
        [_captureSession addInput:input];
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [_captureSession addOutput:_metadataOutput];
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.layer insertSublayer:_previewLayer atIndex:0];
    }
    
    if (capturing) {
        [_captureSession startRunning];
        _metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    } else {
        [_captureSession stopRunning];
        _camera = nil;
        _captureSession = nil;
        [_previewLayer removeFromSuperlayer];
        _previewLayer = nil;
        _metadataOutput = nil;
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSArray *facesBySize = [metadataObjects sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        CGFloat size1 = [obj1 bounds].size.width * [obj1 bounds].size.height;
        CGFloat size2 = [obj2 bounds].size.width * [obj2 bounds].size.height;
        return size2 - size1;
    }];
    self.faces = facesBySize.count > 0 ? @[facesBySize.firstObject] : @[];
}

- (void)setFaces:(NSArray<AVMetadataFaceObject *> *)faces {
    _faces = faces;
    NSMutableArray *views = self.faceViews.mutableCopy ? : [NSMutableArray new];
    while (views.count < faces.count) {
        UIView *view = [UIView new];
        view.layer.borderColor = [UIColor greenColor].CGColor;
        view.layer.borderWidth = 2;
        [views addObject:view];
    }
    while (views.count > faces.count) {
        [views removeLastObject];
    }
    self.faceViews = views;
}

- (void)setFaceViews:(NSArray *)faceViews {
    for (UIView *v in self.faceViews) {
        if (![faceViews containsObject:v]) {
            [v removeFromSuperview];
        }
    }
    _faceViews = faceViews;
    for (UIView *v in faceViews) {
        if (!v.superview) {
            [self addSubview:v];
        }
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _previewLayer.frame = self.bounds;
    for (NSInteger i=0; i<self.faceViews.count; i++) {
        UIView *faceView = self.faceViews[i];
        AVMetadataFaceObject *face = self.faces[i];
        CGRect newFrame = [_previewLayer rectForMetadataOutputRectOfInterest:face.bounds];
        if (faceView.frame.size.width > 0) {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                faceView.frame = newFrame;
            } completion:nil];
        } else {
            faceView.frame = newFrame;
        }
    }
}

@end
