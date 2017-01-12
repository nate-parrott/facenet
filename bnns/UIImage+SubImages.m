//
//  UIImage+SubImages.m
//  Faces
//
//  Created by Nate Parrott on 1/22/13.
//  Copyright (c) 2013 Nate Parrott. All rights reserved.
//

#import "UIImage+SubImages.h"

@implementation UIImage (SubImages)

-(UIImage*)fn_subImage:(CGRect)rect {
    UIGraphicsBeginImageContext(rect.size);
    [self drawInRect:CGRectMake(-rect.origin.x, -rect.origin.y, self.size.width, self.size.height)];
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return subImage;
}

@end
