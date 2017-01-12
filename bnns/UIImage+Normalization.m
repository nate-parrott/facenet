//
//  UIImage+Normalization.m
//  Faces
//
//  Created by Nate Parrott on 1/25/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "UIImage+Normalization.h"

@implementation UIImage (Normalization)

-(UIImage*)fn_normalizedImage {
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    UIImage* normalized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalized;
}

@end
