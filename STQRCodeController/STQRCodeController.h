//
//  STQRCodeController.h
//  STQRCodeController
//
//  Created by ST on 16/11/28.
//  Copyright © 2016年 ST. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, STQRCodeResultType) {
    STQRCodeResultTypeSuccess = 0, // 1.成功获取图片中的二维码信息
    STQRCodeResultTypeNoInfo = 1,  // 2.识别的图片没有二维码信息
    STQRCodeResultTypeError = 2   // 3.其他错误
};

@class STQRCodeController;

@protocol STQRCodeControllerDelegate <NSObject>
- (void)qrcodeController:(STQRCodeController *)qrcodeController readerScanResult:(NSString *)readerScanResult type:(STQRCodeResultType)resultType;
@end

@interface STQRCodeController : UIViewController
@property(nonatomic, weak)id<STQRCodeControllerDelegate>delegate;
// 点击控制器返回事件 与 成功控制器返回事件
- (void)backButtonEvent;
- (void)backSuccessEvent;
@end

NS_ASSUME_NONNULL_END
