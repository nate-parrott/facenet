//
//  ViewController.m
//  bnns
//
//  Created by Nate Parrott on 1/11/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "ViewController.h"
#import "FNCameraView.h"

@interface ViewController ()

@property (nonatomic) FNCameraView *cameraView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraView = [FNCameraView new];
    [self.view addSubview:self.cameraView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.cameraView.frame = self.view.bounds;
}

@end
