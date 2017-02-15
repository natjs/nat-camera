package com.nat.camera;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.provider.MediaStore;

import java.io.File;
import java.io.IOException;
import java.util.Date;
import java.util.HashMap;

/**
 * Created by xuqinchao on 17/1/7.
 *  Copyright (c) 2017 Nat. All rights reserved.
 */

public class HLCameraModule {

    File finalImageFile = null;
    File videoFile = null;
    boolean mIsTakingPhoto = false;
    boolean mIsTakingVideo = false;
    long mCaptureImgStartTime = System.currentTimeMillis();
    long mCaptureVideoStartTime = System.currentTimeMillis();

    private Context mContext;
    private static volatile HLCameraModule instance = null;

    private HLCameraModule(Context context){
        mContext = context;
    }

    public static HLCameraModule getInstance(Context context) {
        if (instance == null) {
            synchronized (HLCameraModule.class) {
                if (instance == null) {
                    instance = new HLCameraModule(context);
                }
            }
        }

        return instance;
    }

    public void captureImage(Activity activity, final HLModuleResultListener listener){
        if (mIsTakingPhoto) {
            listener.onResult(HLUtil.getError(HLConstant.CAMERA_BUSY, HLConstant.CAMERA_BUSY_CODE));
            return;
        }
        mCaptureImgStartTime = System.currentTimeMillis();

        mIsTakingPhoto = true;

        String fileName = "nat_img_" + new Date().getTime() + ".jpg";
        Intent intent = new Intent();
        intent.setAction(MediaStore.ACTION_IMAGE_CAPTURE);
        intent.addCategory(Intent.CATEGORY_DEFAULT);
        try {
            finalImageFile = HLUtil.getHLFile(fileName);
        } catch (IOException e) {
            e.printStackTrace();
            listener.onResult(HLUtil.getError(HLConstant.CAMERA_INTERNAL_ERROR, HLConstant.CAMERA_INTERNAL_ERROR_CODE));
        }
        Uri uri = Uri.fromFile(finalImageFile);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);

        activity.startActivityForResult(intent, HLConstant.HL_IMAGE_REQUEST_CODE);
    }

    public Object onCaptureImgActivityResult(int requestCode, int resultCode, Intent data){
        if (requestCode != HLConstant.HL_IMAGE_REQUEST_CODE) return null;

        mIsTakingPhoto = false;
        if (resultCode == Activity.RESULT_OK) {
            String absolutePath = finalImageFile.getAbsolutePath();
            HashMap<String, String> result = new HashMap<String, String>();
            result.put("path", absolutePath);
            return result;
        } else {
            long endTime = System.currentTimeMillis();
            if (endTime - mCaptureImgStartTime <= 10) {
                return HLUtil.getError(HLConstant.CAMERA_PERMISSION_DENIED, HLConstant.CAMERA_PERMISSION_DENIED_CODE);
            }
            return null;
        }
    }

    public void captureVideo(Activity activity, final HLModuleResultListener listener) {
        if (mIsTakingVideo) {
            listener.onResult(HLUtil.getError(HLConstant.CAMERA_BUSY, HLConstant.CAMERA_BUSY_CODE));
            return;
        }

        final long startTime = System.currentTimeMillis();
        mIsTakingVideo = true;
        String fileName = "nat_video_" + new Date().getTime() + ".mov";
        Intent intent = new Intent();
        intent.setAction(MediaStore.ACTION_VIDEO_CAPTURE);
        intent.addCategory(Intent.CATEGORY_DEFAULT);
        try {
            videoFile = HLUtil.getHLFile(fileName);
        } catch (IOException e) {
            e.printStackTrace();
        }
        Uri uri = Uri.fromFile(videoFile);
        intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
        activity.startActivityForResult(intent, HLConstant.HL_VIDEO_REQUEST_CODE);
    }

    public Object onCaptureVideoActivityResult(int requestCode, int resultCode, Intent data){
        if (requestCode != HLConstant.HL_VIDEO_REQUEST_CODE) return null;

        mIsTakingVideo = false;
        if (resultCode == Activity.RESULT_OK) {
            String absolutePath = videoFile.getAbsolutePath();
            HashMap<String, String> result = new HashMap<String, String>();
            result.put("path", absolutePath);
            return result;
        }else {
            long endTime = System.currentTimeMillis();
            if (endTime - mCaptureVideoStartTime <= 10) {
                return HLUtil.getError(HLConstant.CAMERA_PERMISSION_DENIED, HLConstant.CAMERA_PERMISSION_DENIED_CODE);
            }
            return null;
        }
    }
}
