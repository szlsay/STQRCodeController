# STQRCodeController
一个简易的二维码识别控制器

# 使用方法
添加对iOS10的支持
在info.plist中添加

	<key>NSCameraUsageDescription</key>
	<string>开启相机</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>开启相册</string>

# 版本信息
## 1.0
1. 支持iOS8以上，分别在iOS8.2、iOS9.3、iOS10.1的系统中测试通过
2. 支持图片识别，可从相册中获取
3. 支持闪关灯，如果设备不支持闪关灯，闪光灯按钮将不显示


