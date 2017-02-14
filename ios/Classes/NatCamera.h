//
//  NatCamera.h
//
//  Created by huangyake on 17/1/7.
//  Copyright © 2017 Nat. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NatCamera : NatManager<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

+ (NatCamera *)singletonManger;

- (void)captureImage:(NSDictionary *)params :(NatCallback)callback;

- (void)captureVideo:(NSDictionary *)params :(NatCallback)callback;

@end
