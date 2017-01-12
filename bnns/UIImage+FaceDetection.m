//
//  UIImage+FaceDetection.m
//  Faces
//
//  Created by Nate Parrott on 1/22/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "UIImage+FaceDetection.h"
#import "UIImage+Normalization.h"
#import "CIFeature+CorrectedBounds.h"

@implementation UIImage (FaceDetection)

-(NSArray<CIFaceFeature *>*)fn_detectFaces {
    CIContext* context = [CIContext contextWithOptions:nil];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    CIImage* image = [CIImage imageWithCGImage:[self fn_normalizedImage].CGImage];
    return (NSArray<CIFaceFeature *> *)[detector featuresInImage:image];
}

//-(UIImage*)drawFaces {
//    UIGraphicsBeginImageContext(self.size);
//    [self drawAtPoint:CGPointZero];
//    for (CIFaceFeature* face in [self detectFaces]) {
//        [[UIColor redColor] setStroke];
//        [[UIBezierPath bezierPathWithRect:[face correctedBoundsInImage:self]] stroke];
//        for (int i=0; i<3; i++) {
//            CGPoint point = face.leftEyePosition;
//            if (i==1) point = face.rightEyePosition;
//            else if (i==2) point = face.mouthPosition;
//            [[UIColor blueColor] setStroke];
//            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x-2, self.size.height-point.y-2, 4, 4)] stroke];
//        }
//    }
//    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return result;
//}

@end
