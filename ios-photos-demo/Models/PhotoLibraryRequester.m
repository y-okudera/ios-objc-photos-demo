//
//  PhotoLibraryRequester.m
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/20.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

#import "PhotoLibraryRequester.h"

@implementation PhotoLibraryRequester

#pragma mark - class methods

+ (void)loadThumbnailImageForAsset:(PHAsset *)photoAsset resultHandler:(ResultHandler)resultHandler {
    CGSize targetSize = CGSizeMake(160, 160);
    [self loadImageForAsset:photoAsset
                 targetSize:targetSize
              resultHandler:resultHandler];
}

+ (void)loadPreviewImageForAsset:(PHAsset *)photoAsset resultHandler:(ResultHandler)resultHandler {
    [self loadImageForAsset:photoAsset
                 targetSize:PHImageManagerMaximumSize
              resultHandler:resultHandler];
}

#pragma mark - instance methods

- (void)execute {
    
    __weak typeof(self) wself = self;
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        switch (status) {
            case PHAuthorizationStatusNotDetermined:
                [wself.delegate notDetermined];
                break;
                
            case PHAuthorizationStatusAuthorized:
                [wself fetchAssets];
                break;
                
            case PHAuthorizationStatusDenied:
                [wself.delegate denied];
                break;
                
            case PHAuthorizationStatusRestricted:
                [wself.delegate restricted];
                break;
        }
    }];
}

#pragma mark - private methods

+ (void)loadImageForAsset:(PHAsset *)photoAsset
               targetSize:(CGSize)targetSize
            resultHandler:(ResultHandler)resultHandler {
    
    PHImageRequestOptions *imageRequestOptions = [PHImageRequestOptions new];
    imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PHImageManager defaultManager] requestImageForAsset:photoAsset
                                                   targetSize:targetSize
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:imageRequestOptions
                                                resultHandler:resultHandler];
    });
}

- (void)fetchAssets {
    
    NSMutableArray<PHAsset *> *photoAssets = [@[] mutableCopy];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [photoAssets addObject:(PHAsset *)obj];
    }];
    
    [self.delegate authorized:photoAssets];
}

@end
