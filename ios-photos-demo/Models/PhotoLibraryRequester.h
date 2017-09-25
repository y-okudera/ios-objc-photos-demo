//
//  PhotoLibraryRequester.h
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/20.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

@import Foundation;
@import Photos;

typedef void (^ResultHandler)(UIImage *result, NSDictionary *info);

@protocol PhotoLibraryRequestStatus <NSObject>

/**
 PhotoLibraryの利用可否が未選択
 */
- (void)notDetermined;

/**
 PhotoLibraryの利用を許可されている

 @param photoAssets PhotoLibraryの画像情報の配列
 */
- (void)authorized:(NSArray<PHAsset *> *)photoAssets;

/**
 PhotoLibraryの利用を拒否されている
 */
- (void)denied;

/**
 PhotoLibraryが機能制限などで利用できない
 */
- (void)restricted;
@end

@interface PhotoLibraryRequester : NSObject
@property (weak, nonatomic) id<PhotoLibraryRequestStatus>delegate;

/**
 写真選択画面用のサムネイル画像読み込み
 */
+ (void)loadThumbnailImageForAsset:(PHAsset *)photoAsset resultHandler:(ResultHandler)resultHandler;

/**
 写真プレビュー画面のオリジナルサイズの画像読み込み
 */
+ (void)loadPreviewImageForAsset:(PHAsset *)photoAsset resultHandler:(ResultHandler)resultHandler;

/**
 PhotoLibraryのアクセス要求
 */
- (void)execute;
@end
