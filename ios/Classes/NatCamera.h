//
//  NatCamera.h
//
//  Created by huangyake on 17/1/7.
//  Copyright © 2017 Nat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NatCamera : NSObject<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
typedef void (^NatCallback)(id error, id result);

+ (NatCamera *)singletonManger;
- (void)captureImage:(NSDictionary *)params :(NatCallback)callback;
- (void)captureVideo:(NSDictionary *)params :(NatCallback)callback;

@end
