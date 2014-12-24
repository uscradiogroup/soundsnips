//
//  AppDelegate.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/20/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplashScreenViewController.h"
#import "ModelManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate, ModelManagerDelegate>

@property (strong, nonatomic) UIWindow*						window;
@property (strong, nonatomic) SplashScreenViewController*	splashScreenViewController;
@property (strong, nonatomic) UITabBarController*			tabBarController;

@end
