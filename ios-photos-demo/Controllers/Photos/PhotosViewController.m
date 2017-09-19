//
//  PhotosViewController.m
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/20.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

#import "PhotoCollectionViewCell.h"
#import "PhotosViewController.h"
#import "PhotoLibraryRequester.h"

@interface PhotosViewController () <PhotoLibraryRequestStatus>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) PhotoLibraryRequester *photoLibraryRequester;
@property (nonatomic) NSArray<PHAsset *> *photoAssets;
@property (nonatomic) NSMutableArray<NSData *> *selectedPhotoDataArray;
@end

@implementation PhotosViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - actions

- (IBAction)didTapCancelButton:(UIBarButtonItem *)sender {
    NSLog(@"データ件数(リセット前): %ld", self.selectedPhotoDataArray.count);
    
    // 選択状態のItemを全て非選択状態にする
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    self.selectedPhotoDataArray = [@[] mutableCopy];
    [self.collectionView reloadData];
    
    NSLog(@"データ件数(リセット後): %ld", self.selectedPhotoDataArray.count);
}

- (IBAction)didTapDoneButton:(UIBarButtonItem *)sender {
    NSLog(@"データ件数: %ld", self.selectedPhotoDataArray.count);
    for (NSData *data in self.selectedPhotoDataArray) {
        NSLog(@"データサイズ: %ld", data.length);
    }
}

#pragma mark - private methods

- (void)setup {
    
    self.collectionView.allowsMultipleSelection = YES;
    self.selectedPhotoDataArray = [@[] mutableCopy];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoLibraryRequest)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)photoLibraryRequest {
    self.photoLibraryRequester = [PhotoLibraryRequester new];
    self.photoLibraryRequester.delegate = self;
    self.photoAssets = @[];
    [self.photoLibraryRequester execute];
}

#pragma mark - PhotoLibraryRequestStatus

- (void)notDetermined {
    NSLog(@"%@ %s [Line: %d]", NSStringFromClass([self class]), __func__, __LINE__);
}

- (void)authorized:(NSArray<PHAsset *> *)photoAssets {
    NSLog(@"%@ %s [Line: %d]", NSStringFromClass([self class]), __func__, __LINE__);
    
    self.photoAssets = photoAssets;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [self.collectionView reloadData];
        }
    });
}

- (void)denied {
    NSLog(@"%@ %s [Line: %d]", NSStringFromClass([self class]), __func__, __LINE__);
    
#warning 設定アプリに飛ばすことは可能だが、設定アプリで権限が変更されるとアプリが終了する
    // 参考: https://stackoverflow.com/questions/39269232/correct-way-to-handle-change-in-settings-for-ios
    
    NSString *message = @"PhotoLibraryの使用を許可してください。\n設定アプリでPhotoLibraryの権限を変更すると一度アプリを終了します。";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"キャンセル" style:UIAlertActionStyleCancel handler:nil];
    
    typedef void (^SettingActionHandler)(UIAlertAction *action);
    SettingActionHandler handler = ^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:@"App-Prefs:root=Privacy&path=PHOTOS"];
        if ([UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url
                                             options:@{}
                                   completionHandler:nil];
        }
    };
    
    UIAlertAction *settingAction = [UIAlertAction actionWithTitle:@"設定" style:UIAlertActionStyleDefault handler:handler];
    [alertController addAction:cancelAction];
    [alertController addAction:settingAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)restricted {
    NSLog(@"%@ %s [Line: %d]", NSStringFromClass([self class]), __func__, __LINE__);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    
    return self.photoAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[PhotoCollectionViewCell identifier]
                                                                                                         forIndexPath:indexPath];
    
    cell.selectedView.hidden = !cell.isSelected;
    
    if (cell.imageView.image) {
        cell.imageView.image = nil;
    }
    
    CGSize targetSize = CGSizeMake(160, 160);
    PHImageRequestOptions *imageRequestOptions = [PHImageRequestOptions new];
    imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    typedef void (^ResultHandler)(UIImage *result, NSDictionary *info);
    ResultHandler resultHandler = ^(UIImage *result, NSDictionary *info) {
        cell.imageView.image = result;
        [cell layoutSubviews];
    };
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PHImageManager defaultManager] requestImageForAsset:wself.photoAssets[indexPath.row]
                                                   targetSize:targetSize
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:imageRequestOptions
                                                resultHandler:resultHandler];
    });
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    cell.selected = YES;
    cell.selectedView.hidden = NO;
    
    NSData *imageData = [[NSData alloc] initWithData:UIImagePNGRepresentation(cell.imageView.image)];
    if (![self.selectedPhotoDataArray containsObject:imageData]) {
        [self.selectedPhotoDataArray addObject:imageData];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    cell.selected = NO;
    cell.selectedView.hidden = YES;
    
    NSData *imageData = [[NSData alloc] initWithData:UIImagePNGRepresentation(cell.imageView.image)];
    if ([self.selectedPhotoDataArray containsObject:imageData]) {
        [self.selectedPhotoDataArray removeObject:imageData];
    }
}

@end
