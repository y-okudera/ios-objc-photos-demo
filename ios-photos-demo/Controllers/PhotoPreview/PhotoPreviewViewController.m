//
//  PhotoPreviewViewController.m
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/26.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

@import UIKit;
#import "PhotoLibraryRequester.h"
#import "PhotoPreviewViewController.h"
#import "PhotoPreviewTableViewCell.h"

@interface PhotoPreviewViewController () <UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSMutableArray <UIImage *> *photos;
@end

@implementation PhotoPreviewViewController

#pragma mark - factory method

+ (PhotoPreviewViewController *)createWithPhotoAssets:(NSArray <PHAsset *> *)photoAssets {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PhotoPreviewViewController" bundle:nil];
    PhotoPreviewViewController *vc = [storyboard instantiateInitialViewController];
    vc.photoAssets = photoAssets;
    return vc;
}

#pragma mark - view life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

#pragma mark - private methods

- (void)setup {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完了"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(didTapDoneButton)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)didTapDoneButton {
    self.photos = [@[] mutableCopy];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    ResultHandler resultHandler = ^(UIImage *result, NSDictionary *info) {
        [self.photos addObject:result];
        if (self.photos.count == self.photoAssets.count) {
            NSLog(@"読み込み完了 %ld/%ld", self.photos.count, self.photoAssets.count);
            // MARK: 選択した順のUIImage*の配列
            NSLog(@"%@", self.photos);
        } else {
            NSLog(@"読み込み中... %ld/%ld", self.photos.count, self.photoAssets.count);
        }
        
        dispatch_semaphore_signal(semaphore);
    };
    for (PHAsset *photoAsset in self.photoAssets) {
        [PhotoLibraryRequester loadPreviewImageForAsset:photoAsset
                                          resultHandler:resultHandler];
        while(dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.photoAssets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [PhotoPreviewTableViewCell identifier];
    PhotoPreviewTableViewCell *cell = (PhotoPreviewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                                                                   forIndexPath:indexPath];
    
    ResultHandler resultHandler = ^(UIImage *result, NSDictionary *info) {
        cell.photoPreview.image = result;
        [cell layoutSubviews];
    };
    [PhotoLibraryRequester loadPreviewImageForAsset:self.photoAssets[indexPath.row]
                                      resultHandler:resultHandler];
    return cell;
}

@end
