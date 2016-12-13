//
//  NSBundle+STQRCodeController.h
//  STQRCodeController
//
//  Created by ST on 16/11/29.
//  Copyright © 2016年 ST. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSBundle (STQRCodeController)

+ (instancetype)st_qrcodeControllerBundle;
+ (UIImage *)st_qrcodeControllerImageWithName:(NSString *)name;

@end
