//
//  UIImagePickerController+Expand.h
//  jike
//
//  Created by tauCross on 16/3/14.
//  Copyright © 2016年 tauCross. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef void (^ImagePickerCompleteBlock) (UIImagePickerController *picker, NSDictionary *info);
typedef void (^ImagePickerCancelBlock) (UIImagePickerController *picker);



@interface UIImagePickerController (Expand)<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (void)showFromViewController:(UIViewController *)controller completeBlock:(ImagePickerCompleteBlock)completeBlock cancelBlock:(ImagePickerCancelBlock)cancelBlock;

@end
