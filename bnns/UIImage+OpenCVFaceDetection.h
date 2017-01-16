//
//  UIImage+OpenCVFaceDetection.h
//  bnns
//
//  Created by Nate Parrott on 1/16/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (OpenCVFaceDetection)

- (NSArray *)fn_findFaces;
- (UIImage *)fn_cropToFaceRect:(CGRect)rect;

@end
