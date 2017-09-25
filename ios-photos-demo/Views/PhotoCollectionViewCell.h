//
//  PhotoCollectionViewCell.h
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/20.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

@import Photos;
@import UIKit;

@interface PhotoCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *selectedView;
@property (nonatomic) PHAsset *photoAsset;

+ (NSString *)identifier;
@end
