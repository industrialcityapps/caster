//
//  ICViewController.h
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@class ICPathView;

@interface ICViewController : UIViewController

@property(nonatomic, strong) IBOutlet ICPathView *pathView;
@property(nonatomic, strong) IBOutlet CPTGraphHostingView *xGraphHostingView;
@property(nonatomic, strong) IBOutlet CPTGraphHostingView *yGraphHostingView;

@end
