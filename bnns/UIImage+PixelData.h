//
//  UIImage+PixelData.h
//  ScantronKit
//
//  Created by Nate Parrott on 9/16/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagePixelData : NSObject

@property (nonatomic) UInt8 *bytes;
@property (nonatomic) NSUInteger width, height;

- (float)brightnessAtX:(NSInteger)x y:(NSInteger)y;
- (double)averageBrightnessInRect:(CGRect)rect;

@end

@interface UIImage ()

- (ImagePixelData *)pixelData;

- (float *)floatArray;

@end

