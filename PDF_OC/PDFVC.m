//
//  PDFVC.m
//  PDFViewer
//
//  Created by 123456 on 2017/6/20.
//  Copyright © 2017年 123456. All rights reserved.
//

#import "PDFVC.h"
#import <PDFKit/PDFKit.h>
#import <Masonry.h>


@interface PDFVC ()
{
    PDFView * pdfView;
}
@end

@implementation PDFVC

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *title = @"C程序设计语言(K&amp;R)清晰中文版";
    self.navigationItem.title = title;
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *path = [[NSBundle mainBundle]pathForResource:title ofType:@"pdf"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    PDFDocument *pdfDoucment = [[PDFDocument alloc]initWithURL:url];
    // 初始化可能失败
    if (pdfDoucment) {
        pdfView = [[PDFView alloc]init];
        pdfView.document = pdfDoucment;

        pdfView.displayDirection = kPDFDisplayDirectionVertical;
//        pdfView.displayMode = kPDFDisplaySinglePageContinuous;
//        pdfView.displaysAsBook = YES;
//        pdfView.autoScales = YES;
        CGSize size = pdfView.documentView.frame.size;
        if (size.width>0) {
            pdfView.scaleFactor = self.view.frame.size.width/size.width;
        }else{
            NSLog(@"----------- 什么鬼");
            pdfView.scaleFactor = 1;
        }

        [self.view addSubview:pdfView];
        __weak typeof(self)weakSelf = self;
        [pdfView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.equalTo(weakSelf.view);
            make.left.equalTo(weakSelf.view);
            make.top.equalTo(weakSelf.view);
            make.bottom.equalTo(weakSelf.view);
            make.width.equalTo(weakSelf.view);
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            if([pdfView canGoToFirstPage]){
                [UIView animateWithDuration:0 animations:^{
                    [pdfView goToFirstPage:nil];
                }];
            }
        });
    }
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
