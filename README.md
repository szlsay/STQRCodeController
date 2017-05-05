# STQRCodeController

![License MIT](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)
![Pod version](https://img.shields.io/cocoapods/v/STQRCodeController.svg?style=flat)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform info](https://img.shields.io/cocoapods/p/STQRCodeController.svg?style=flat)](http://cocoadocs.org/docsets/STQRCodeController)

一个简单使用的二维码识别控制器，代码量不到1000行

## 使用方法

使用举例：

	STQRCodeController *codeVC = [[STQRCodeController alloc]init];
		codeVC.delegate = self;
    UINavigationController *navVC = [[UINavigationController alloc]initWithRootViewController:codeVC];
    [self presentViewController:navVC animated:YES completion:nil];


添加对iOS10的支持
在info.plist中添加

	<key>NSCameraUsageDescription</key>
	<string>开启相机</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>开启相册</string>
 
## 效果图
![](https://raw.githubusercontent.com/STShenZhaoliang/STImage/master/STQRCodeController/STQRCodeController.gif)

## [版本信息](https://github.com/STShenZhaoliang/STQRCodeController/blob/master/CHANGELOG.md)
