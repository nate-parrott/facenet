//
//  FNCameraViewController.m
//  bnns
//
//  Created by Nate Parrott on 1/13/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "FNCameraViewController.h"
#import "FNCameraView.h"

@interface FNCameraViewController ()

@property (nonatomic) FNCameraView *cameraView;

@end

@implementation FNCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraView = [FNCameraView new];
    [self.view insertSubview:self.cameraView atIndex:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.cameraView.frame = self.view.bounds;
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
