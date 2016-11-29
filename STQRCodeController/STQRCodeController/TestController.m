//
//  TestController.m
//  STQRCodeController
//
//  Created by ST on 16/11/28.
//  Copyright © 2016年 ST. All rights reserved.
//

#import "TestController.h"
#import "STQRCodeController.h"
#import "STQRCodeAlert.h"
@interface TestController ()<STQRCodeControllerDelegate>
/** 1. */
@property(nonatomic, strong)UIButton *buttonGoQR;
@end

@implementation TestController

#pragma mark - --- 1.init 生命周期 ---

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.buttonGoQR];
}

#pragma mark - --- 2.delegate 视图委托 ---
- (void)qrcodeController:(STQRCodeController *)qrcodeController readerScanResult:(NSString *)readerScanResult type:(STQRCodeResultType)resultType
{
     NSLog(@"%s %@", __FUNCTION__, readerScanResult);
     NSLog(@"%s %lu", __FUNCTION__, (unsigned long)resultType);
    [STQRCodeAlert showWithTitle:readerScanResult];
}
#pragma mark - --- 3.event response 事件相应 ---

#pragma mark - --- 4.private methods 私有方法 ---
- (void)gotoQR {
    STQRCodeController *codeVC = [[STQRCodeController alloc]init];
    codeVC.delegate = self;
    UINavigationController *navVC = [[UINavigationController alloc]initWithRootViewController:codeVC];
    [self presentViewController:navVC animated:YES completion:nil];
}
#pragma mark - --- 5.setters 属性 ---

#pragma mark - --- 6.getters 属性 —--
- (UIButton *)buttonGoQR
{
    if (!_buttonGoQR) {
        _buttonGoQR = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 200, 44)];
        [_buttonGoQR setTitle:@"跳转到二维码界面" forState:UIControlStateNormal];
        [_buttonGoQR setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_buttonGoQR setBackgroundColor:[UIColor magentaColor]];
        _buttonGoQR.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [_buttonGoQR addTarget:self action:@selector(gotoQR) forControlEvents:UIControlEventTouchUpInside];
    }
    return _buttonGoQR;
}
@end
