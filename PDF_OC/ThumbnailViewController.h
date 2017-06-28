//
//  ThumbnailViewController.h
//  PDF_OC
//
//  Created by pengding on 2017/6/28.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PDFKit/PDFKit.h>
@interface ThumbnailViewController : UICollectionViewController
@property(nonatomic,strong)PDFDocument *pdfDocument;//!< document对象，pdfview所附带的
@property(nonatomic,strong)PDFView *pdfView;
@end
