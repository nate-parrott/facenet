//
//  UIImage+MainFace.m
//  bnns
//
//  Created by Nate Parrott on 1/12/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "UIImage+MainFace.h"
#import "UIImage+FaceDetection.h"
#import "UIImage+SubImages.h"

@implementation UIImage (MainFace)

- (UIImage *)fn_mainFace {
    NSArray *faces = [self fn_detectFaces];
    // find largest face:
    faces = [faces sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        CGFloat size1 = [obj1 bounds].size.width * [obj1 bounds].size.height;
        CGFloat size2 = [obj2 bounds].size.width * [obj2 bounds].size.height;
        return size2 - size1;
    }];
    if (faces.count) {
        return [self fn_cropToFace:faces[0]];
    } else {
        return nil;
    }
}

- (UIImage *)fn_cropToFace:(CIFaceFeature *)face {
    return [self fn_cropToFaceInRect:[face correctedBoundsInImage:self]];
}

- (UIImage *)fn_cropToFaceInRect:(CGRect)faceBounds {
    CGFloat width = faceBounds.size.width / 0.7;
    CGFloat height = 192.0 / 160.0 * width;
    CGFloat centerX = CGRectGetMidX(faceBounds);
    CGFloat centerY = CGRectGetMidY(faceBounds);
    return [self fn_subImage:CGRectMake(centerX - width/2, centerY - height/2, width, height)];
}

@end
