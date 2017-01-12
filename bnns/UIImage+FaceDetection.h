//
//  UIImage+FaceDetection.h
//  Faces
//
//  Created by Nate Parrott on 1/22/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>
#import "CIFeature+CorrectedBounds.h"

@interface UIImage (FaceDetection)

-(NSArray<CIFaceFeature *>*)fn_detectFaces;

// -(UIImage*)drawFaces;

@end
