//
//  FNResultsViewController.m
//  bnns
//
//  Created by Nate Parrott on 1/13/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "FNResultsViewController.h"
#import "FaceNet.h"
#import "UIImage+MainFace.h"

@interface FNResultsViewController ()

@property (nonatomic,weak) IBOutlet UITextView *textView;

@end

@implementation FNResultsViewController

- (void)setFace:(CIFaceFeature *)face inImage:(UIImage *)image {
    [self loadViewIfNeeded];
    NSDictionary *data = [[FaceNet shared] attributesForFace:[image fn_cropToFace:face]];
    NSMutableString *s = [NSMutableString new];
    for (NSString *key in data) {
        [s appendFormat:@"%@: %@\n", key, data[key]];
    }
    self.textView.text = s;
}

- (IBAction)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
