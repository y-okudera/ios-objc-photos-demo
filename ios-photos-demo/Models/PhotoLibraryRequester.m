//
//  PhotoLibraryRequester.m
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/20.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

#import "PhotoLibraryRequester.h"

@implementation PhotoLibraryRequester

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

- (void)fetchAssets {
    
    NSMutableArray<PHAsset *> *photoAssets = [@[] mutableCopy];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [photoAssets addObject:(PHAsset *)obj];
    }];
    
    [self.delegate authorized:photoAssets];
}

@end
