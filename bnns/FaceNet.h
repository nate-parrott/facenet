//
//  FaceNet.h
//  bnns
//
//  Created by Nate Parrott on 1/11/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

@import UIKit;

@interface FaceNet : NSObject

- (UIImage *)preprocessImage:(UIImage *)face;

- (void)xorTest;
- (void)convTest;
- (void)faceTest;

@end
