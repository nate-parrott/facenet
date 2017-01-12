//
//  UIImage+Resize.m
//  bnns
//
//  Created by Nate Parrott on 1/12/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)atSize:(CGSize)size {
    UIGraphicsImageRendererFormat *fmt = [[UIGraphicsImageRendererFormat alloc] init];
    fmt.scale = 1;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:fmt];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    }];
}

@end
