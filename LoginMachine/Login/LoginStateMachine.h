//
//  LoginStateMachine.h
//  PuDong-C
//
//  Created by 吴克赛 on 2017/3/29.
//  Copyright © 2017年 BarnettWu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LoginIntent) {
    LoginIntentMobile,//  必须绑定
    LoginIntentWechat,//  微信和手机都可以
    LoginIntentSwitch,//  切换
};

typedef NS_ENUM(NSUInteger, LoginMode) {
//    LoginModeMobile,//手机和微信，需要绑定手机
    LoginModeMobileAndWechat,//手机和微信
    LoginModeBind,  //绑定手机
};

typedef NS_ENUM(NSUInteger, LoginState) {
    LoginStateNone,     //未登录
    LoginStateMobile,   //手机
    LoginStateWechat,   //微信
    LoginStateWechatAndMobile,  //微信且手机
};

typedef void(^SimpleAction)();

@interface LoginStateMachine : NSObject

+ (LoginStateMachine *)sharedMachine;

@property (nonatomic, assign) LoginMode mode;

@property (nonatomic, assign) LoginState state;

@property (nonatomic, strong) id cookie;

@property (nonatomic, copy) SimpleAction mobileSucAction;//手机登录成功后
@property (nonatomic, copy) SimpleAction cancelLoginAction;//不登录返回


- (void)loginWithIntent:(LoginIntent)intent;

- (void)loginWithIntentOnTopViewController:(LoginIntent)intent;

- (void)logout;

- (void)addServoOnLoginDelegate:(id)servo ;

@end
