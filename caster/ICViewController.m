//
//  ICViewController.m
//  caster
//
//  Created by Jonah Williams on 7/21/12.
//  Copyright (c) 2012 Industrial City Apps. All rights reserved.
//

#import "ICViewController.h"
#import "ICGestureRecognizer.h"
#import "ICPathView.h"
#import "ICTouch.h"
#import "ICPath.h"

@interface ICViewController ()

@property(nonatomic, strong) ICGestureRecognizer *gestureRecognizer;
@property(nonatomic, strong) NSArray *graphedPaths;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation ICViewController

@synthesize gestureRecognizer = _IC_gestureRecognizer;
@synthesize pathView = _IC_pathView;
@synthesize xGraphHostingView = _IC_xGraphHostingView;
@synthesize yGraphHostingView = _IC_yGraphHostingView;
@synthesize graphedPaths = _IC_graphedPaths;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer 
{
    NSArray *plots = [self.xGraphHostingView.hostedGraph allPlots];
    for (CPTPlot *plot in plots) {
        plot.dataSource = nil;
        [self.xGraphHostingView.hostedGraph removePlot:plot];
    }
    plots = [self.yGraphHostingView.hostedGraph allPlots];
    for (CPTPlot *plot in plots) {
        plot.dataSource = nil;
        [self.yGraphHostingView.hostedGraph removePlot:plot];
    }
    
    self.pathView.paths = [(ICGestureRecognizer *)gestureRecognizer bezierPaths];
    
    self.graphedPaths = [(ICGestureRecognizer *)gestureRecognizer paths];

    for (ICPath *path in self.graphedPaths) {
        NSInteger index = [self.graphedPaths indexOfObject:path];
        
        [path computeAttributes];
        
        NSArray *colors = [NSArray arrayWithObjects:[CPTColor redColor], [CPTColor blueColor], [CPTColor orangeColor], [CPTColor greenColor], [CPTColor yellowColor], [CPTColor purpleColor], [CPTColor magentaColor], [CPTColor grayColor], [CPTColor brownColor], nil];

        // X axis
        CPTBarPlot *plot = [CPTBarPlot tubularBarPlotWithColor:[colors objectAtIndex:index] horizontalBars:NO];

        CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
        barLineStyle.lineColor = [colors objectAtIndex:index];
        barLineStyle.lineWidth = 1.0;

        plot.barWidth = CPTDecimalFromDouble(0.01);
        plot.barOffset = CPTDecimalFromDouble(index * 0.1);
        plot.lineStyle = barLineStyle;
        plot.name = @"X";
        
        plot.dataSource = path;
        [self.xGraphHostingView.hostedGraph addPlot:plot];
        
        // Y axis
        plot = [CPTBarPlot tubularBarPlotWithColor:[colors objectAtIndex:index] horizontalBars:NO];
        
        plot.barWidth = CPTDecimalFromDouble(0.01);
        plot.barOffset = CPTDecimalFromDouble(index * 0.1);
        plot.lineStyle = barLineStyle;
        plot.name = @"Y";
        
        plot.dataSource = path;
        [self.yGraphHostingView.hostedGraph addPlot:plot];
    }
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.gestureRecognizer = [[ICGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    self.pathView.multipleTouchEnabled = YES;
    [self.pathView addGestureRecognizer:self.gestureRecognizer];
    
    CPTGraph *xGraph = [[CPTXYGraph alloc] initWithFrame:self.xGraphHostingView.bounds];
    xGraph.plotAreaFrame.masksToBorder = NO;

    [xGraph applyTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];    
    xGraph.paddingBottom = 1.0f;      
    xGraph.paddingLeft  = 1.0f;
    xGraph.paddingTop    = 1.0f;
    xGraph.paddingRight  = 1.0f;

    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;

    xGraph.title = @"FFT - X";
    xGraph.name = @"X";
    xGraph.titleTextStyle = titleStyle;
    xGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    xGraph.titleDisplacement = CGPointMake(0.0f, -16.0f);

    CGFloat xMin = 0.0f;
    CGFloat xMax = 5;
    CGFloat yMin = 0.0f;
    CGFloat yMax = 8.0f;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) xGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];
        
    self.xGraphHostingView.hostedGraph = xGraph;
    
    CPTGraph *yGraph = [[CPTXYGraph alloc] initWithFrame:self.xGraphHostingView.bounds];
    yGraph.plotAreaFrame.masksToBorder = NO;
    
    [yGraph applyTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];    
    yGraph.paddingBottom = 1.0f;      
    yGraph.paddingLeft  = 1.0f;
    yGraph.paddingTop    = 1.0f;
    yGraph.paddingRight  = 1.0f;
    
    yGraph.title = @"FFT - Y";  
    yGraph.titleTextStyle = titleStyle;
    yGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    yGraph.titleDisplacement = CGPointMake(0.0f, -16.0f);
    
    plotSpace = (CPTXYPlotSpace *) yGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];
    
    self.yGraphHostingView.hostedGraph = yGraph;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.gestureRecognizer = nil;
    self.pathView = nil;
    self.xGraphHostingView = nil;
    self.yGraphHostingView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
