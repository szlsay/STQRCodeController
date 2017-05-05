//
//  STQRCodeReaderView.m
//  STQRCodeController
//
//  Created by ST on 16/11/28.
//  Copyright © 2016年 ST. All rights reserved.
//

#import "STQRCodeReaderView.h"
#import <AVFoundation/AVFoundation.h>
#import "STQRCodeConst.h"
#import "NSBundle+STQRCodeController.h"
#import <ImageIO/ImageIO.h>

@interface STQRCodeReaderView ()<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
/** 1.中间扫描图片 */
@property(nonatomic, strong)UIImageView *imageScanZone;
/** 2.扫描的尺寸 */
@property(nonatomic, assign)CGRect rectScanZone;
/** 3.获取会话 */
@property(nonatomic, strong)AVCaptureSession *captureSession;
/** 4.遮罩视图 */
@property(nonatomic, strong)UIView *viewMask;
/** 5.开启闪光灯 */
@property(nonatomic, strong)UIButton *buttonTurn;
/** 6.移动的图片 */
@property(nonatomic, strong)UIImageView *imageMove;
/** 7.提示语 */
@property(nonatomic, strong)UILabel *labelAlert;
/** 8.获取视频输出 */
@property(nonatomic, strong)AVCaptureVideoDataOutput *captureVideoDataOutput;

/** 开始扫描动画 */
- (void)startAnimation;

/** 关闭扫描动画 */
- (void)stopAnimation;

@end


@implementation STQRCodeReaderView

#pragma mark - --- 1.init 生命周期 ---

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupDefault];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefault];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageScanZone.frame = self.rectScanZone;
    self.buttonTurn.center = CGPointMake(self.imageScanZone.center.x, CGRectGetMaxY(self.imageScanZone.frame) + 100);
    self.labelAlert.center = CGPointMake(self.imageScanZone.center.x, CGRectGetMaxY(self.imageScanZone.frame) + 20);
}

- (void)setupDefault
{
    // 1.基本属性
    [self setFrame:CGRectMake(0, 0, ST_QRCODE_ScreenWidth, ST_QRCODE_ScreenHeight)];
    [self setBackgroundColor:[UIColor blackColor]];
    [self addSubview:self.viewMask];
    [self addSubview:self.imageMove];
    [self addSubview:self.imageScanZone];
    [self addSubview:self.buttonTurn];
    [self addSubview:self.labelAlert];
    
    _openDetection = YES;
    
    // 2.采样的区域
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.layer.bounds;
    [self.layer insertSublayer:layer atIndex:0];
    
    // 3.如果不支持闪光灯，不显示闪光灯按钮
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.buttonTurn.hidden = !device.hasTorch;
}

#pragma mark - --- 2.delegate 视图委托 ---


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    /**
     *  1.获取CMSampleBuffer的数目,0的话没有数据,发生错误了.
     *  2.CMSampleBuffer 无效
     *  3.CMSampleBuffer 数据没准备好
     */
    if (self.openDetection) {
        if ((CMSampleBufferGetNumSamples(sampleBuffer) == 0) || !CMSampleBufferIsValid(sampleBuffer) || !CMSampleBufferDataIsReady(sampleBuffer)) {
            //为无效的 CMSampleBuffer ,没有必要进行后面的逻辑!
            return;
        }
        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,
                                                                     sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        NSDictionary *metadata = [[NSMutableDictionary alloc]
                                  initWithDictionary:(__bridge NSDictionary*)metadataDict];
        CFRelease(metadataDict);
        NSDictionary *exifMetadata = [[metadata
                                       objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
        float brightnessValue = [[exifMetadata
                                  objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
        NSLog(@"%s %f", __FUNCTION__, brightnessValue);
        if (brightnessValue <= 0) {
            if (!self.buttonTurn.selected) {
                self.openDetection = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self turnTorchEvent:self.buttonTurn];
                    [self setTurnOn:YES];
                    //              [self.captureSession removeOutput:self.captureVideoDataOutput];
                });
                
            }
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects && metadataObjects.count > 0 ) {
        AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects[0];
        //输出扫描字符串
        if (self.delegate && [self.delegate respondsToSelector:@selector(qrcodeReaderView:readerScanResult:)]) {
            [self.delegate qrcodeReaderView:self readerScanResult:metadataObject.stringValue];
        }
    }
    
    [self stopScan];
}

#pragma mark - --- 3.event response 事件相应 ---

- (void)startScan
{
    [self.captureSession startRunning];
    [self startAnimation];
}

- (void)stopScan
{
    [self.captureSession stopRunning];
    [self stopAnimation];
}

- (void)turnTorchEvent:(UIButton *)button
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device hasFlash]){
        [device lockForConfiguration:nil];
        if (!button.selected) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
        }
        [device unlockForConfiguration];
    }
}

- (void)startAnimation
{
    CGFloat viewW = 200*ST_QRCODE_WidthRate;
    CGFloat viewH = 3;
    CGFloat viewX = (ST_QRCODE_ScreenWidth - viewW)/2;
    __block CGFloat viewY = (ST_QRCODE_ScreenHeight- viewW)/2;
    __block CGRect rect = CGRectMake(viewX, viewY, viewW, viewH);
    [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionRepeat animations:^{
        viewY = (ST_QRCODE_ScreenHeight- viewW)/2 + 200*ST_QRCODE_WidthRate - 5;
        rect = CGRectMake(viewX, viewY, viewW, viewH);
        self.imageMove.frame = rect;
    } completion:^(BOOL finished) {
        viewY = (ST_QRCODE_ScreenHeight- viewW)/2;
        rect = CGRectMake(viewX, viewY, viewW, viewH);
        self.imageMove.frame = rect;
    }];
}

- (void)stopAnimation
{
    CGFloat viewW = 200*ST_QRCODE_WidthRate;
    CGFloat viewH = 3;
    CGFloat viewX = (ST_QRCODE_ScreenWidth - viewW)/2;
    __block CGFloat viewY = (ST_QRCODE_ScreenHeight- viewW)/2;
    __block CGRect rect = CGRectMake(viewX, viewY, viewW, viewH);
    [UIView animateWithDuration:0.01 animations:^{
        self.imageMove.frame = rect;
    }];
}
#pragma mark - --- 4.private methods 私有方法 ---

-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    CGFloat x,y,width,height;
    x = (CGRectGetHeight(readerViewBounds)-CGRectGetHeight(rect))/2/CGRectGetHeight(readerViewBounds);
    y = (CGRectGetWidth(readerViewBounds)-CGRectGetWidth(rect))/2/CGRectGetWidth(readerViewBounds);
    width = CGRectGetHeight(rect)/CGRectGetHeight(readerViewBounds);
    height = CGRectGetWidth(rect)/CGRectGetWidth(readerViewBounds);
    return CGRectMake(x, y, width, height);
}
#pragma mark - --- 5.setters 属性 ---

- (void)setTurnOn:(BOOL)turnOn
{
    _turnOn = turnOn;
    self.buttonTurn.selected = turnOn;
}
    
#pragma mark - --- 6.getters 属性 —--

- (UIImageView *)imageScanZone{
    if (!_imageScanZone) {
        _imageScanZone = [[UIImageView alloc]initWithImage:[NSBundle st_qrcodeControllerImageWithName:@"st_scanBackground@2x"]];
    }
    return _imageScanZone;
}

- (CGRect)rectScanZone
{
    return CGRectMake(60*ST_QRCODE_WidthRate, (ST_QRCODE_ScreenHeight-200*ST_QRCODE_WidthRate)/2, 200*ST_QRCODE_WidthRate, 200*ST_QRCODE_WidthRate);
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        //获取摄像设备
        AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //创建输入流
        AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        //创建输出流
        AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
        //设置代理 在主线程里刷新
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        CGRect scanCrop=[self getScanCrop:self.rectScanZone readerViewBounds:self.frame];
        output.rectOfInterest = scanCrop;
        
        //初始化链接对象
        _captureSession = [[AVCaptureSession alloc]init];
        //高质量采集率
        [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        if (input) {
            [_captureSession addInput:input];
        }
        if (output) {
            [_captureSession addOutput:output];
            //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
            NSMutableArray *array = [[NSMutableArray alloc] init];
            if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
                [array addObject:AVMetadataObjectTypeQRCode];
            }
            if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
                [array addObject:AVMetadataObjectTypeEAN13Code];
            }
            if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
                [array addObject:AVMetadataObjectTypeEAN8Code];
            }
            if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
                [array addObject:AVMetadataObjectTypeCode128Code];
            }
            output.metadataObjectTypes = array;
        }
        
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
            _captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;//4k
        }else if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]){
            _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;//1080P
        }else if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
            _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;//1080P
        }else if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]){
            _captureSession.sessionPreset = AVCaptureSessionPresetHigh;//High
        }else{
            //weakSelf.captureSession.sessionPreset = deafault value (AVCaptureSessionPresetHigh)
        }
        
        
        //session addOutput
        if ([_captureSession canAddOutput:self.captureVideoDataOutput]) {
            [_captureSession addOutput:self.captureVideoDataOutput];
        }

    }
    return _captureSession;
}

- (AVCaptureVideoDataOutput *)captureVideoDataOutput{
    if (!_captureVideoDataOutput) {
        //
        _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        /*
         .videoSettings 如果设置为nil , 之后才读取.videoSettings 不会是nil ,而是AVCaptureSession.sessionPreset的值 , 这就表示 以无压缩的格式 接收视频帧
         在iOS上, videoSettings 唯一支持的key 只有kCVPixelBufferPixelFormatTypeKey
         value只有3种:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange / kCVPixelFormatType_420YpCbCr8BiPlanarFullRange / kCVPixelFormatType_32BGRA
         */
        _captureVideoDataOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        //丢弃掉延迟的视频帧,不再传给buffer queue
        _captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("com.CircleLi_VideoDataOutputQueue.www", DISPATCH_QUEUE_SERIAL);//必须是串行队列, 保证视频帧按顺序传递
        [_captureVideoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
    }
    return _captureVideoDataOutput;
}

- (UIView *)viewMask
{
    if (!_viewMask) {
        _viewMask = [[UIView alloc]initWithFrame:self.bounds];
        [_viewMask setBackgroundColor:[UIColor blackColor]];
        [_viewMask setAlpha:102.0/255];
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path appendPath:[UIBezierPath bezierPathWithRect:_viewMask.bounds]];
        [path appendPath:[UIBezierPath bezierPathWithRect:self.rectScanZone].bezierPathByReversingPath];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = path.CGPath;
        _viewMask.layer.mask = maskLayer;
    }
    return _viewMask;
}

- (UIImageView *)imageMove
{
    if (!_imageMove) {
        CGFloat viewW = 200*ST_QRCODE_WidthRate;
        CGFloat viewH = 3;
        CGFloat viewX = (ST_QRCODE_ScreenWidth - viewW)/2;
        CGFloat viewY = (ST_QRCODE_ScreenHeight- viewW)/2;
        _imageMove = [[UIImageView alloc]initWithFrame:CGRectMake(viewX, viewY, viewW, viewH)];
        _imageMove.image = [NSBundle st_qrcodeControllerImageWithName:@"st_scanLine@2x"];
    }
    return _imageMove;
}

- (UIButton *)buttonTurn
{
    if (!_buttonTurn) {
        _buttonTurn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonTurn setBackgroundImage:[NSBundle st_qrcodeControllerImageWithName:@"st_lightSelect@2x"] forState:UIControlStateNormal];
        [_buttonTurn setBackgroundImage:[NSBundle st_qrcodeControllerImageWithName:@"st_lightNormal@2x"] forState:UIControlStateSelected];
        [_buttonTurn sizeToFit];
        [_buttonTurn addTarget:self action:@selector(turnTorchEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _buttonTurn;
}

- (UILabel *)labelAlert
{
    if (!_labelAlert) {
        CGFloat viewW = ST_QRCODE_ScreenWidth;
        CGFloat viewH = 17;
        CGFloat viewX = 0;
        CGFloat viewY = 0;
        _labelAlert = [[UILabel alloc]initWithFrame:CGRectMake(viewX, viewY, viewW, viewH)];
        [_labelAlert setText:@"将二维码/条形码放置框内，即开始扫描"];
        [_labelAlert setTextColor:[UIColor whiteColor]];
        [_labelAlert setFont:[UIFont systemFontOfSize:15]];
        [_labelAlert setTextAlignment:NSTextAlignmentCenter];
    }
    return _labelAlert;
}
@end
