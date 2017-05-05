//
//  STQRCodeController.m
//  STQRCodeController
//
//  Created by ST on 16/11/28.
//  Copyright © 2016年 ST. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "STQRCodeController.h"
#import "STQRCodeReaderView.h"
#import "STQRCodeAlert.h"

#import "NSBundle+STQRCodeController.h"
#import "STQRCodeConst.h"
@interface STQRCodeController ()<STQRCodeReaderViewDelegate,AVCaptureMetadataOutputObjectsDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate>{
    // 1.记录之前的状态
    UIBarStyle _originBarStyle;
}
/** 1.读取二维码界面 */
@property(nonatomic, strong)STQRCodeReaderView *readview;
/** 2.图片探测器 */
@property(nonatomic, strong)CIDetector *detector;
/** 4.定时器 */
@property(nonatomic, strong)NSTimer *timer ;
@end

@implementation STQRCodeController
    
#pragma mark - --- 1.init 生命周期 ---
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.设置标题和背景色
    self.title = @"扫描";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 2.设置UIBarButtonItem， iOS8系统之后才支持本地扫描
    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc]initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(alumbEvent)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    UIBarButtonItem * leftItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonEvent)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    //     self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonEvent)];
    
    [self.view addSubview:self.readview];
    
    // 3.添加进入前后台的事件监控
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}
    
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _originBarStyle = self.navigationController.navigationBar.barStyle;
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
}
    
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    [self authorizationStatus];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 4.添加闪关灯的监听事件
    if (device.hasFlash) {
        [device addObserver:self forKeyPath:@"torchMode" options:NSKeyValueObservingOptionNew context:nil];
    }
}
    
- (void)authorizationStatus{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self.readview startScan];
    }else {
        [STQRCodeAlert showWithTitle:@"请在设置中开启摄像头权限"];
        [self.readview stopScan];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:YES];
    }
}
    
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self.readview stopScan];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device.hasFlash) {
        [device removeObserver:self forKeyPath:@"torchMode"];
        [self.readview setTurnOn:NO];
    }
    
    [self.navigationController.navigationBar setBarStyle:_originBarStyle];
}
    
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}
    
#pragma mark - --- 2.delegate 视图委托 ---
#pragma mark - --- UIImagePickerController Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1.获取图片信息
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    // 2.退出图片控制器
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
        
        NSArray *features = [self.detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count) { // 1.识别到二维码
            
            // 1.播放提示音
            [self playSystemSound];
            
            // 2.显示扫描结果信息
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            //            [STQRCodeAlert showWithTitle:feature.messageString];
            
            if ([self.delegate respondsToSelector:@selector(qrcodeController:readerScanResult:type:)]) {
                [self.delegate qrcodeController:self readerScanResult:feature.messageString type:STQRCodeResultTypeSuccess];
                [self backSuccessEvent];
            }
        }else {
            [STQRCodeAlert showWithTitle:@"没有识别到二维码信息\n请重新选择图片"];
            if ([self.delegate respondsToSelector:@selector(qrcodeController:readerScanResult:type:)]) {
                [self.delegate qrcodeController:self readerScanResult:@"" type:STQRCodeResultTypeNoInfo];
                //                [self backEvent];
            }
        }
    }];
}
    
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    }];
}
    
#pragma mark - --- STQRCodeReaderView Delegate
    
- (void)qrcodeReaderView:(STQRCodeReaderView *)qrcodeReaderView readerScanResult:(NSString *)readerScanResult
{
    // 1.播放提示音
    [self playSystemSound];
    
    // 2.显示扫描结果信息
    //    [STQRCodeAlert showWithTitle:readerScanResult];
    
    if ([self.delegate respondsToSelector:@selector(qrcodeController:readerScanResult:type:)]) {
        [self.delegate qrcodeController:self readerScanResult:readerScanResult type:STQRCodeResultTypeSuccess];
        [self backSuccessEvent];
    }else {
        // 重新扫描
        //        [self.readview performSelector:@selector(startScan) withObject:nil afterDelay:2];
    }
}
    
    
#pragma mark - --- 3.event response 事件相应 ---
// 1.点击返回操作
- (void)backButtonEvent
{
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

// 2.成功获取信息返回操作
- (void)backSuccessEvent{
    [self backButtonEvent];
}

// 3.相册事件
- (void)alumbEvent
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) { //判断设备是否支持相册
        [STQRCodeAlert showWithTitle:@"未开启访问相册权限，请在设置中开始"];
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    imagePickerController.allowsEditing = YES;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:^{
        [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
    }];
}

// 4.播放提示音
- (void)playSystemSound{
    SystemSoundID soundID;
    NSString *strSoundFile = [[NSBundle st_qrcodeControllerBundle] pathForResource:@"st_noticeMusic" ofType:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:strSoundFile],&soundID);
    AudioServicesPlaySystemSound(soundID);
}
    
#pragma mark - --- 4.private methods 私有方法 ---
    
// 1.监听摄像头权限
- (void)observeAuthrizationStatusChange{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self.timer invalidate];
        self.timer = nil;
        [self.readview startScan];
    }
}
    
// 2.监听系统闪关灯的是否打开
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([@"torchMode" isEqualToString:keyPath]) {
        if ([@"1" isEqualToString:[NSString stringWithFormat:@"%@", change[@"new"]]]) {
            [self.readview setTurnOn:YES];
        }else{
            [self.readview setTurnOn:NO];
        }
    }
}
    
// 3.进入前台，重新刷新扫描
- (void)willEnterForeground
{
    if (self.readview) {
        [self.readview stopScan];
        [self performSelector:@selector(authorizationStatus) withObject:self afterDelay:0.1];
    }
}
    
    
- (BOOL)shouldAutorotate
{
    return NO;
}
    
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
    
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
    
#pragma mark - --- 5.setters 属性 ---
    
#pragma mark - --- 6.getters 属性 —--
    
- (STQRCodeReaderView *)readview
{
    if (!_readview) {
        _readview = [[STQRCodeReaderView alloc]init];
        _readview.delegate = self;
    }
    return _readview;
}
    
- (CIDetector *)detector
{
    if (!_detector) {
        _detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    }
    return _detector;
}
    @end

