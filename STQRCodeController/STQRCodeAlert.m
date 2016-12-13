//
//  STQRCodeAlert.m
//  STQRCodeController
//
//  Created by ST on 16/11/28.
//  Copyright © 2016年 ST. All rights reserved.
//

#import "STQRCodeAlert.h"

NS_ASSUME_NONNULL_BEGIN

@interface STQRCodeAlert ()
/** 1.文本框 */
@property(nonatomic, strong)UILabel *labelTitle ;
@end

NS_ASSUME_NONNULL_END

@implementation STQRCodeAlert

#pragma mark - --- 1.init 生命周期 ---

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bounds = [UIScreen mainScreen].bounds;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.labelTitle];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = [UIScreen mainScreen].bounds;
    [self.labelTitle setCenter:CGPointMake(CGRectGetWidth(bounds)/2, CGRectGetHeight(bounds)/2)];
}


#pragma mark - --- 2.delegate 视图委托 ---

#pragma mark - --- 3.event response 事件相应 ---

#pragma mark - --- 4.private methods 私有方法 ---
- (void)show
{
    [self.labelTitle.layer setOpacity:0];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self setCenter:[UIApplication sharedApplication].keyWindow.center];
    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.labelTitle.layer setOpacity:1.0];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(remove) withObject:self afterDelay:1];
    }];
}

- (void)remove
{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.labelTitle.layer setOpacity:0.0];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - --- 5.setters 属性 ---

+ (void)showWithTitle:(NSString *)title
{
    STQRCodeAlert *alertView = [[STQRCodeAlert alloc]init];
    [alertView.labelTitle setText:title];
    [alertView.labelTitle sizeToFit];
    CGSize size = alertView.labelTitle.frame.size;
    alertView.labelTitle.frame = CGRectMake(0, 0, size.width + 12, size.height+16);
    [alertView show];
}
#pragma mark - --- 6.getters 属性 —--

- (UILabel *)labelTitle
{
    if (!_labelTitle) {
        _labelTitle = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 0)];
        [_labelTitle setTextColor:[UIColor whiteColor]];
        [_labelTitle setTextAlignment:NSTextAlignmentCenter];
        [_labelTitle setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
        [_labelTitle setFont:[UIFont systemFontOfSize:15]];
        [_labelTitle.layer setCornerRadius:4];
        [_labelTitle setNumberOfLines:0];
        [_labelTitle.layer setMasksToBounds:YES];
    }
    return _labelTitle;
}
@end

