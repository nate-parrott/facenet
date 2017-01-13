//
//  FNFacePickerViewController.m
//  bnns
//
//  Created by Nate Parrott on 1/13/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

#import "FNFacePickerViewController.h"
#import "UIImage+FaceDetection.h"
#import "FNResultsViewController.h"
#import "CIFeature+CorrectedBounds.h"

@interface FNFacePickerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) UIImage *image;
@property (nonatomic) IBOutlet UIView *faceButtonsContainer;

@property (nonatomic) NSArray<CIFaceFeature *> *faces;
@property (nonatomic) NSArray<UIButton *> *faceButtons;

@end

@implementation FNFacePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    self.imageView.image = image;
    self.faces = [image fn_detectFaces];
}

- (void)setFaces:(NSArray<CIFaceFeature *> *)faces {
    _faces = faces;
    NSMutableArray *buttons = [NSMutableArray new];
    for (CIFaceFeature *face in faces) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.layer.borderColor = [UIColor greenColor].CGColor;
        b.layer.borderWidth = 2;
        [b addTarget:self action:@selector(tappedFace:) forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:b];
    }
    self.faceButtons = buttons;
}

- (void)setFaceButtons:(NSArray<UIButton *> *)faceButtons {
    for (UIButton *old in _faceButtons) [old removeFromSuperview];
    _faceButtons = faceButtons;
    for (UIButton *b in _faceButtons) [self.faceButtonsContainer addSubview:b];
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    for (NSInteger i=0; i<self.faceButtons.count; i++) {
        CIFaceFeature *face = self.faces[i];
        UIButton *button = self.faceButtons[i];
        CGRect faceRect = [self rectForFace:face];
        [button setFrame:[button.superview convertRect:faceRect fromView:self.imageView]];
    }
}

- (CGRect)rectForFace:(CIFaceFeature *)face {
    // in imageView coordinates:
    CGRect fb = [face correctedBoundsInImage:self.image];
    fb = CGRectMake(fb.origin.x / self.image.size.width, fb.origin.y / self.image.size.height, fb.size.width / self.image.size.width, fb.size.height / self.image.size.height);
    CGRect imageRect = [self rectForImageContent];
    return CGRectMake(imageRect.origin.x + imageRect.size.width * fb.origin.x, imageRect.origin.y + imageRect.size.height * fb.origin.y, imageRect.size.width * fb.size.width, imageRect.size.height * fb.size.height);
}

- (CGRect)rectForImageContent {
    if (!self.image) return CGRectZero;
    
    CGFloat scale = MIN(self.imageView.bounds.size.width / self.image.size.width, self.imageView.bounds.size.height / self.image.size.height);
    CGSize size = CGSizeMake(self.image.size.width * scale, self.image.size.height * scale);
    return CGRectMake((self.imageView.bounds.size.width - size.width)/2, (self.imageView.bounds.size.height - size.height)/2, size.width, size.height);
}

- (void)tappedFace:(UIButton *)button {
    NSInteger i = [self.faceButtons indexOfObject:button];
    CIFaceFeature *face = self.faces[i];
    UINavigationController *resultsNav = [self.storyboard instantiateViewControllerWithIdentifier:@"ResultsNav"];
    FNResultsViewController *resultsVC = (id)resultsNav.viewControllers.firstObject;
    [resultsVC setFace:face inImage:self.image];
    [self presentViewController:resultsNav animated:YES completion:nil];
}

- (IBAction)pickImage:(id)sender {
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    self.image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showCamera:(id)sender {
    [self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"] animated:YES completion:nil];
}

@end
