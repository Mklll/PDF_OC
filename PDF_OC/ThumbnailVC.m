//
//  ThumbnailVC.m
//  PDF_OC
//
//  Created by pengding on 2017/6/28.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import "ThumbnailVC.h"
#import <Masonry.h>

@interface ThumbnailVC ()
{
    PDFThumbnailView *thumbnailView ;
}
@property (nonatomic ,strong ) NSMutableArray * dataArray ;//!<  数据源数组
@property (nonatomic ,assign ) CGSize cellSize;//!<  cel
@end

@implementation ThumbnailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setPdfView:(PDFView *)pdfView{
    _pdfView = pdfView;
    thumbnailView = [[PDFThumbnailView alloc]init];
    thumbnailView.PDFView = _pdfView;
    thumbnailView.thumbnailSize = self.cellSize;
    [self.view addSubview:thumbnailView];
    [self.view bringSubviewToFront:thumbnailView];
    __weak typeof(self)weakSelf = self;
    [thumbnailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.view);
    }];

}
- (CGSize)cellSize{
    return CGSizeMake(60, 60);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
