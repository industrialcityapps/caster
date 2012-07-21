//
//  ICAppDelegate.h
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Carbon Five. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ICViewController;

@interface ICAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ICViewController *viewController;

@end
