//
//  LoginStateMachine.m
//  PuDong-C
//
//  Created by 吴克赛 on 2017/3/29.
//  Copyright © 2017年 BarnettWu. All rights reserved.
//

#import "LoginStateMachine.h"
#import "BntThirdLogin.h"
#import "LoginViewController.h"
#import "PDNavigationController.h"
#import "UIViewController+Bnt.h"
#import "BntUMClickManager.h"
//#import "AppDelegate.h"
#import "PDUserInfoDB.h"
#import "Login.h"

#define LoginStateKey @"LoginState"

@interface LoginStateMachine ()<LoginControllerDelegate>

@property (nonatomic, assign) LoginIntent intent;

@end

@implementation LoginStateMachine

@synthesize state=_state;

+ (LoginStateMachine *)sharedMachine {
    static LoginStateMachine *sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *dic = [PDUserInfoDB readUserDataforKey:LoginStateKey];
        if ([dic valueForKey:@"state"]) {
            _state = [[dic valueForKey:@"state"] integerValue];
        }
    }
    return self;
}

- (void)setState:(LoginState)state {
    _state = state;
    NSDictionary *dic = @{@"state":[NSString stringWithFormat:@"%@",@(state)]};
    [PDUserInfoDB storageUserData:dic forKey:LoginStateKey];
}

- (void)addServoOnLoginDelegate:(LoginViewController *)servo {
    servo.delegate = self;
}

- (LoginState)state {
    if ([Login sharedLogin].account.sessionId &&
        [BntThirdLogin sharedLogin].isWXLogin) {
        return LoginStateWechatAndMobile;
    }else if ([Login sharedLogin].account.sessionId) {
        return LoginStateMobile;
    }else if ([[BntThirdLogin sharedLogin].isWXLogin isEqual:@YES]) {
        return LoginStateWechat;
    }
    return LoginStateNone;
}

- (void)logout {
    [[Login sharedLogin] logout];
    [[BntThirdLogin sharedLogin] exitWXLogin];
    [self mobileLoginSuccessProfileTrackEnd];
}

//  入口
- (void)loginWithIntent:(LoginIntent)intent {
    _intent = intent;
    if (intent == LoginIntentSwitch) {
        _mode = LoginModeMobileAndWechat;
        [self loginControllerPresent];
        return;
    }
    switch (self.state) {
        case LoginStateWechatAndMobile:
        case LoginStateMobile:{//已登录手机
            [self mobileCompleteOperation];
        }
            break;
        case LoginStateWechat:{//已登录微信
            if (intent == LoginIntentMobile) {
                _mode = LoginModeBind;//绑定
                [self loginControllerPresent];
            }else {
                _mode = LoginModeMobileAndWechat;
                [self loginControllerPresent];
            }
        }
            break;
        default:{// 没有登录
            _mode = LoginModeMobileAndWechat;
            [self loginControllerPresent];
        }
            break;
    }
}

- (void)loginWithIntentOnTopViewController:(LoginIntent)intent {
    _intent = intent;
    if (intent == LoginIntentSwitch) {
        _mode = LoginModeMobileAndWechat;
        [self loginControllerPresentOnTopViewController];
        return;
    }
    switch (self.state) {
        case LoginStateWechatAndMobile:
        case LoginStateMobile:{//已登录手机
            [self mobileCompleteOperation];
        }
            break;
        case LoginStateWechat:{//已登录微信
            if (intent == LoginIntentMobile) {
                _mode = LoginModeBind;//绑定
                [self loginControllerPresentOnTopViewController];
            }else {
                _mode = LoginModeMobileAndWechat;
                [self loginControllerPresentOnTopViewController];
            }
        }
            break;
        default:{// 没有登录
            _mode = LoginModeMobileAndWechat;
            [self loginControllerPresentOnTopViewController];
        }
            break;
    }
}

//  出口
- (void)loginComplete:(LoginResult)success {
    [self updateCookie];
    if (success == LoginResultMobileSuccess) {// after手机登录
        
        [self loginControllerDismiss];
        [self mobileCompleteOperation];
        //账户统计
        [self mobileLoginSuccessProfileTrackStart];
    }else if(success == LoginResultWechatSuccess) {// after微信登录
        if (_intent == LoginIntentMobile) {// 需要绑定
            _mode = LoginModeBind;
            [self loginControllerBind];
        }else if (_intent == LoginIntentWechat){
            [self loginControllerDismiss];
        }
    }
}

//  cancel login
- (BOOL)loginCancel {
    if (_cancelLoginAction) {
        _cancelLoginAction();
        _cancelLoginAction = nil;
        return YES;
    }
    return NO;
}

- (void)mobileCompleteOperation {
    if (_mobileSucAction) {
        _mobileSucAction();
        _mobileSucAction = nil;
    }
}

- (void)loginControllerPresentOnTopViewController {
    LoginViewController *vc = [[LoginViewController alloc] init];
    PDNavigationController *nvc = [[PDNavigationController alloc] initWithRootViewController:vc];
    vc.delegate = self;
    UIViewController *rvc = [UIViewController topViewController];
    [rvc presentViewController:nvc animated:YES completion:nil];
}

- (void)loginControllerPresent {
    LoginViewController *vc = [[LoginViewController alloc] init];
    PDNavigationController *nvc = [[PDNavigationController alloc] initWithRootViewController:vc];
    vc.delegate = self;
    UIViewController *rvc = [[UIApplication sharedApplication].delegate window].rootViewController;
    [rvc presentViewController:nvc animated:YES completion:nil];
}

- (void)loginControllerOn:(UIViewController *)controller {
    LoginViewController *vc = [[LoginViewController alloc] init];
    PDNavigationController *nvc = [[PDNavigationController alloc] initWithRootViewController:vc];
    vc.delegate = self;
    [controller presentViewController:nvc animated:YES completion:nil];
}

- (void)loginControllerBind {
    UIViewController *vc = [UIViewController topViewController];
    LoginViewController *lvc = [[LoginViewController alloc] init];
    lvc.delegate = self;
    [vc.navigationController pushViewController:lvc animated:YES];
}

- (void)loginControllerDismiss {
    UIViewController *vc = [UIViewController topViewController];
    [vc dismissToRootViewController:nil];
}

/** update cookie */
- (void)updateCookie {
    Login *login = [Login sharedLogin];
    LoginStateMachine *logMac = [LoginStateMachine sharedMachine];
    login.user.mobile.length == 11 ? logMac.cookie = login.user.mobile : NO;
}

#pragma mark - click analyse
- (void)mobileLoginSuccessProfileTrackStart {
    [BntClickManager profileSignInWithPUID:[Login sharedLogin].user.mobile];
}

- (void)mobileLoginSuccessProfileTrackEnd {
    [BntClickManager profileOff];
}

@end
