Pod::Spec.new do |s|
s.name     = 'STQRCodeController'
s.version  = '1.0'
s.license = { :type => 'MIT', :file => 'LICENSE'}
s.summary  = '千行代码搞定二维码扫描'
s.homepage = 'https://github.com/STShenZhaoliang'
s.author   = { 'STShenZhaoliang' => '409178030@qq.com' }
s.source   = {
:git => 'https://github.com/STShenZhaoliang/STQRCodeController.git',
:tag => s.version.to_s
}
s.ios.deployment_target = '8.0'
s.source_files = "Source/STQRCodeController/*.{h,m}"
s.resource = "Source/Resource/STQRCodeController.bundle"
s.requires_arc = true
end
