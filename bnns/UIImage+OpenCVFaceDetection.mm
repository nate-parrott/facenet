//
//  UIImage+OpenCVFaceDetection.m
//  bnns
//
//  Created by Nate Parrott on 1/16/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "UIImage+OpenCVFaceDetection.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "UIImage+SubImages.h"

@implementation UIImage (OpenCVFaceDetection)

// https://github.com/nate-parrott/juypter-notebooks/blob/master/face-detect.ipynb

- (cv::CascadeClassifier *)fn_cascadeClassifier {
    static cv::CascadeClassifier cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
        cls.load([path UTF8String]);
    });
    return &cls;
}

- (NSArray *)fn_findFaces {
    cv::Mat rgb;
    UIImageToMat(self, rgb);
    cv::Mat gray;
    cv::cvtColor(rgb, gray, cv::COLOR_RGBA2GRAY);
    std::vector<cv::Rect> faces;
    [self fn_cascadeClassifier]->detectMultiScale(gray, faces);
    NSMutableArray *faceArray = [NSMutableArray new];
    for (size_t i=0; i<faces.size(); i++) {
        CGRect rect = CGRectMake(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
        [faceArray addObject:[NSValue valueWithCGRect:rect]];
    }
    return faceArray;
}

- (UIImage *)fn_cropToFaceRect:(CGRect)faceBounds {
    CGFloat width = faceBounds.size.width / 0.65;
    CGFloat height = 192.0 / 160.0 * width;
    CGFloat centerX = CGRectGetMidX(faceBounds);
    CGFloat centerY = CGRectGetMidY(faceBounds);
    return [self fn_subImage:CGRectMake(centerX - width/2, centerY - height/2, width, height)];
}

@end
