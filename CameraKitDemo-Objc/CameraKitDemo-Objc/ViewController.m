//
//  ViewController.m
//  CameraKitDemo-Objc
//
//  Created by Adrian Mateoaea on 15/02/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@import CameraKit;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CKFPreviewView *previewView = [[CKFPreviewView alloc] initWithFrame:self.view.bounds];
    previewView.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view addSubview:previewView];
    
    CKFPhotoSession *session = [[CKFPhotoSession alloc] initWithPosition:CameraPositionBack detection:CameraDetectionNone];
    previewView.session = session;
}

@end
