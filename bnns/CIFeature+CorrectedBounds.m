//
//  CIFeature+CorrectedBounds.m
//  FilterKit
//
//  Created by Nate Parrott on 9/23/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "CIFeature+CorrectedBounds.h"

@implementation CIFeature (CorrectedBounds)

-(CGRect)correctedBoundsInImage:(UIImage*)sourceImage {
    CGRect bounds = self.bounds;
    bounds.origin.y = sourceImage.size.height - bounds.origin.y - bounds.size.height;
    return bounds;
}

@end

#define FACE_BOUNDS_WEIGHT 0.0

@implementation CIFaceFeature (Metrics)

-(CGPoint)faceCenterInImage:(UIImage*)sourceImage {
    CGPoint eyeMidpoint = CGPointMake((self.leftEyePosition.x+self.rightEyePosition.x)/2, (self.leftEyePosition.y+self.rightEyePosition.y)/2);
    CGPoint center1 = CGPointMake((eyeMidpoint.x+self.mouthPosition.x)/2, (eyeMidpoint.y+self.mouthPosition.y)/2);
    center1.y = sourceImage.size.height-center1.y;
    CGRect bbox = [self correctedBoundsInImage:sourceImage];
    CGPoint center2 = CGPointMake(bbox.origin.x+bbox.size.width/2, bbox.origin.y+bbox.size.height/2);
    return CGPointMake(center1.x*(1-FACE_BOUNDS_WEIGHT)+center2.x*FACE_BOUNDS_WEIGHT, center1.y*(1-FACE_BOUNDS_WEIGHT)+center2.y*FACE_BOUNDS_WEIGHT);
}
-(CGFloat)eyeToMouthDistance {
    CGPoint eyeMidpoint = CGPointMake((self.leftEyePosition.x+self.rightEyePosition.x)/2, (self.leftEyePosition.y+self.rightEyePosition.y)/2);
    return sqrtf(powf(eyeMidpoint.x-self.mouthPosition.x, 2)+powf(eyeMidpoint.y-self.mouthPosition.y, 2));
}
-(CGFloat)eyeToEyeDistance {
    return sqrtf(powf(self.leftEyePosition.x-self.rightEyePosition.x, 2) + powf(self.leftEyePosition.y-self.rightEyePosition.y, 2));
}
-(CGFloat)fallbackFaceAngle {
    // if (self.hasFaceAngle) return self.faceAngle;
    return -atan2f(self.rightEyePosition.y-self.leftEyePosition.y, self.rightEyePosition.x-self.leftEyePosition.x);
}
-(CGSize)faceSize {
    CGFloat angle = self.fallbackFaceAngle;
    CGFloat padding = 0.5;
    CGFloat horiz1 = [self eyeToEyeDistance]*(1+padding*2);
    CGFloat vert1 = [self eyeToMouthDistance]*(1+padding*2);
    CGFloat horiz2 = self.bounds.size.width*cosf(angle) + self.bounds.size.height*sinf(angle);
    CGFloat vert2 = self.bounds.size.height*sinf(angle) + self.bounds.size.width*cosf(angle);
    return CGSizeMake(horiz1*(1-FACE_BOUNDS_WEIGHT)+horiz2*FACE_BOUNDS_WEIGHT, vert1*(1-FACE_BOUNDS_WEIGHT)+vert2*FACE_BOUNDS_WEIGHT);
}

@end
