//
//  ThumbnailViewCell.h
//  PDF_OC
//
//  Created by pengding on 2017/6/28.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThumbnailViewCell : UICollectionViewCell
//@property (nonatomic ,strong ) UIImageView * contentImageView ;//!<  缩略图
@property (weak, nonatomic) IBOutlet UIImageView *contentImageView;

@end
