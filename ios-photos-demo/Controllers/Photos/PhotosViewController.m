//
//  PhotosViewController.m
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/20.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

#import "PhotoCollectionViewCell.h"
#import "PhotoLibraryRequester.h"
#import "PhotoPreviewViewController.h"
#import "PhotosViewController.h"

@interface PhotosViewController () <PhotoLibraryRequestStatus>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) PhotoLibraryRequester *photoLibraryRequester;
@property (nonatomic) NSArray<PHAsset *> *photoAssets;
@property (nonatomic) NSMutableArray<PHAsset *> *selectedPhotoAssets;
@end

@implementation PhotosViewController

#pragma mark - view life cycle

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
    
    // 選択状態のItemを全て非選択状態にする
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    self.selectedPhotoAssets = [@[] mutableCopy];
    [self.collectionView reloadData];
    
    NSLog(@"データ件数(リセット後): %ld", self.selectedPhotoAssets.count);
}

- (IBAction)didTapPreviewButton:(UIBarButtonItem *)sender {
    NSLog(@"データ件数: %ld", self.selectedPhotoAssets.count);
    PhotoPreviewViewController *vc = [PhotoPreviewViewController createWithPhotoAssets:self.selectedPhotoAssets];
    [self.navigationController pushViewController:vc animated:true];
}

#pragma mark - private methods

- (void)setup {
    
    self.collectionView.allowsMultipleSelection = YES;
    self.selectedPhotoAssets = [@[] mutableCopy];
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
    NSLog(@"%s [Line: %d]", __PRETTY_FUNCTION__, __LINE__);
}

- (void)authorized:(NSArray<PHAsset *> *)photoAssets {
    NSLog(@"%s [Line: %d]", __PRETTY_FUNCTION__, __LINE__);
    
    self.photoAssets = photoAssets;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [self.collectionView reloadData];
        }
    });
}

- (void)denied {
    NSLog(@"%s [Line: %d]", __PRETTY_FUNCTION__, __LINE__);
    
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
    NSLog(@"%s [Line: %d]", __PRETTY_FUNCTION__, __LINE__);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    
    return self.photoAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [PhotoCollectionViewCell identifier];
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                                                         forIndexPath:indexPath];
    
    cell.selectedView.hidden = !cell.isSelected;
    cell.photoAsset = self.photoAssets[indexPath.row];
    
    if (cell.imageView.image) {
        cell.imageView.image = nil;
    }
    
    ResultHandler resultHandler = ^(UIImage *result, NSDictionary *info) {
        cell.imageView.image = result;
        [cell layoutSubviews];
    };
    [PhotoLibraryRequester loadThumbnailImageForAsset:cell.photoAsset
                                        resultHandler:resultHandler];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    cell.selected = YES;
    cell.selectedView.hidden = NO;
    
    if (![self.selectedPhotoAssets containsObject:cell.photoAsset]) {
        [self.selectedPhotoAssets addObject:cell.photoAsset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    cell.selected = NO;
    cell.selectedView.hidden = YES;
    
    if ([self.selectedPhotoAssets containsObject:cell.photoAsset]) {
        [self.selectedPhotoAssets removeObject:cell.photoAsset];
    }
}

@end
