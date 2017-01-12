//
//  CIFeature+CorrectedBounds.h
//  FilterKit
//
//  Created by Nate Parrott on 9/23/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import <CoreImage/CoreImage.h>
@import UIKit;

@interface CIFeature (CorrectedBounds)

-(CGRect)correctedBoundsInImage:(UIImage*)sourceImage;

@end

@interface CIFaceFeature (Metrics)

-(CGPoint)faceCenterInImage:(UIImage*)sourceImage;
-(CGFloat)eyeToMouthDistance;
-(CGFloat)eyeToEyeDistance;
-(CGFloat)fallbackFaceAngle;

-(CGSize)faceSize;

@end
