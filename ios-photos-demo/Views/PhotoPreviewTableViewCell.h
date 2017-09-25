//
//  PhotoPreviewTableViewCell.h
//  ios-photos-demo
//
//  Created by OkuderaYuki on 2017/09/26.
//  Copyright © 2017年 YukiOkudera. All rights reserved.
//

@import UIKit;

@interface PhotoPreviewTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoPreview;
+ (NSString *)identifier;
@end
