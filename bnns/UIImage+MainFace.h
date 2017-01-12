//
//  UIImage+MainFace.h
//  bnns
//
//  Created by Nate Parrott on 1/12/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreImage;

@interface UIImage (MainFace)

- (UIImage *)fn_mainFace; // can be null;
- (UIImage *)fn_cropToFace:(CIFaceFeature *)face;

@end
