//
//  STQRCodeReaderView.h
//  STQRCodeController
//
//  Created by ST on 16/11/28.
//  Copyright © 2016年 ST. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class STQRCodeReaderView;

@protocol STQRCodeReaderViewDelegate <NSObject>
- (void)qrcodeReaderView:(STQRCodeReaderView *)qrcodeReaderView readerScanResult:(NSString *)readerScanResult;
@end

@interface STQRCodeReaderView : UIView

@property (nonatomic, weak) id<STQRCodeReaderViewDelegate> delegate;

/** 开启扫描 */
- (void)startScan;

/** 关闭扫描 */
- (void)stopScan;
    
/** 1.设置闪关灯开始 */
@property(nonatomic, assign)BOOL turnOn;
@end
NS_ASSUME_NONNULL_END
