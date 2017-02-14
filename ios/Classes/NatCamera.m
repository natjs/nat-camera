//
//  NatCamera.m
//
//  Created by huangyake on 17/1/7.
//  Copyright © 2017 Nat. All rights reserved.
//


#import "NatCamera.h"
#import "UIImagePickerController+Expand.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>


#define KOriginalPhotoImagePath   \
[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"OriginalPhotoImages"]

@interface NatCamera ()

@property(nonatomic, strong)NatCallback videoCallBack;
@property(nonatomic, strong)NSString *locid;
@property(nonatomic, strong)UIImagePickerController *camera;


@end
@implementation NatCamera


+ (NatCamera *)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)captureImage:(NSDictionary *)params :(NatCallback)callback{
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus ==AVAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied)  //用户已经明确否认了这一照片数据的应用程序访问
    {
//         无权限 引导去开启
//        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//        if ([[UIApplication sharedApplication]canOpenURL:url]) {
//            [[UIApplication sharedApplication]openURL:url];
//        }
        callback(@{@"error":@{@"msg":@"CAMERA_PERMISSION_DENIED",@"code":@120020}},nil);
        return;
    }
    if (self.camera) {
        callback(@{@"error":@{@"msg":@"CAMERA_BUSY",@"code":@120030}},nil);
        return;
    }
    
    self.camera = [[UIImagePickerController alloc] init];
    self.camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.camera.allowsEditing = NO;
    [self.camera showFromViewController:[self getCurrentVC] completeBlock:^(UIImagePickerController *picker, NSDictionary *info) {
       
        self.camera = nil;
        UIImage *orImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSLog(@"%@",orImage);
        
        if (orImage == nil) {
            callback(@{@"error":@{@"msg":@"CAMERA_INTERNAL_ERROR",@"code":@120000}},nil);
            return ;
        }
        
        

        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8)
        {
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                
                //1,保存图片到系统相册
            self.locid = [PHAssetChangeRequest creationRequestForAssetFromImage:orImage].placeholderForCreatedAsset.localIdentifier;
            self.locid = [@"nat://static/image/" stringByAppendingString:self.locid];
               
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    callback(nil,@{@"path":self.locid});
                }
                
            }];

            
        }else{
            __block ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
            [lib writeImageToSavedPhotosAlbum:orImage.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                NSString *str = [assetURL resourceSpecifier];
                str = [str substringFromIndex:2];
                str = [@"nat://static/image/" stringByAppendingString:str];
                callback(nil,@{@"path":str});
                
                 }];
 
        }
        
    } cancelBlock:^(UIImagePickerController *picker) {
        self.camera = nil;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
//        callback(@{@"error":@{@"msg":@"CAMERA_CANCEL",@"code":@0}},nil);
    }];

}

- (void)captureVideo:(NSDictionary *)params :(NatCallback)callback{
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus ==AVAuthorizationStatusRestricted || authStatus == ALAuthorizationStatusDenied)  //用户已经明确否认了这一照片数据的应用程序访问
    {
        //         无权限 引导去开启
//        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
//        if ([[UIApplication sharedApplication]canOpenURL:url]) {
//            [[UIApplication sharedApplication]openURL:url];
//        }
        callback(@{@"error":@{@"msg":@"CAMERA_PERMISSION_DENIED",@"code":@120020}},nil);
        return;
    }
    
    if (self.camera) {
        callback(@{@"error":@{@"msg":@"CAMERA_BUSY",@"code":@120030}},nil);
        return;
    }
    self.videoCallBack = callback;
    self.camera = [UIImagePickerController new];
    self.camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.camera.mediaTypes = @[(NSString *)kUTTypeMovie];
    self.camera.delegate = self;
    self.camera.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;   //设置视频质量
    self.camera.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;  //设置摄像头模式为录制视频
    [[self getCurrentVC] presentViewController:self.camera animated:YES completion:^{
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];

    }];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.camera dismissViewControllerAnimated:YES completion:^{
        self.camera = nil;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    }];
//    self.videoCallBack(@{@"error":@{@"msg":@"CAMERA_CANCEL",@"code":@0}},nil);
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"kUTTypeImage"]) {
        //图片保存和展示
        UIImage *image;
        if (picker.allowsEditing) {
            image = [info objectForKey:UIImagePickerControllerEditedImage]; //允许编辑，获取编辑过的图片
        }
        else{
            image = [info objectForKey:UIImagePickerControllerOriginalImage]; //不允许编辑，获取原图片
        }
        
        UIImageWriteToSavedPhotosAlbum(image,nil,nil, nil);
    }
    else if([type isEqualToString:(NSString *)kUTTypeMovie]){
        //视频保存后 播放视频
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *urlPath = [url path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlPath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(urlPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    }
    
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存视频过程中发生错误，错误信息:%@",error.localizedDescription);
        self.videoCallBack(@{@"error":@{@"code":@120000,@"msg":@"CAMERA_INTERNAL_ERROR"}},nil);
    }else{
        NSLog(@"视频保存成功.");
        
        NSString *str = videoPath;
        str = [@"file://" stringByAppendingString:str];
        
        self.videoCallBack(nil,@{@"path":str});
       
        //录制完之后自动播放
//        NSURL *url=[NSURL fileURLWithPath:videoPath];
    }
     [self.camera dismissViewControllerAnimated:YES completion:^{
         self.camera = nil;
         [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
     }];
}

-(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}


- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

@end
