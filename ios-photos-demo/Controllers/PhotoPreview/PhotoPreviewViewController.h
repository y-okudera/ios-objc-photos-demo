//
//  PhotoPreviewViewController.h
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/26.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

@import Photos;
@import UIKit;

/**
 写真プレビュー画面
 */
@interface PhotoPreviewViewController : UIViewController
@property (nonatomic) NSArray<PHAsset *> *photoAssets;
+ (PhotoPreviewViewController *)createWithPhotoAssets:(NSArray <PHAsset *> *)photoAssets;
@end
