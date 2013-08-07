//
//  EAIElevationProfileView.m
//  ElevationTest
//
//  Created by Eric Ito on 8/4/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAIElevationProfileView.h"
#import "EAILocation.h"

@interface EAIElevationProfileView ()<UIGestureRecognizerDelegate> {
    CGMutablePathRef _profilePath;
    CGMutablePathRef _fillPath;
    CGPoint _currentTouchPoint;
}

@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat maxValue;
@property (nonatomic, strong) UILongPressGestureRecognizer *tapHoldGR;
@end

@implementation EAIElevationProfileView

- (id)initWithFrame:(CGRect)frame locations:(NSArray *)locations {
    self = [super initWithFrame:frame];
    if (self) {
        self.locations = locations;
        self.ceilingFactor = .1;
        self.lineColor = [UIColor blueColor];
        self.fillColor = [UIColor redColor];
        self.lineWidth = 3.0f;
        self.tapHoldGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapAndHold:)];
        self.tapHoldGR.delegate = self;
        [self addGestureRecognizer:self.tapHoldGR];
        _currentTouchPoint = CGPointZero;
    }
    return self;
}

- (void)tapAndHold:(UILongPressGestureRecognizer*)sender {
    CGPoint pt = [sender locationInView:self];
//    NSLog(@"pt: %@", NSStringFromCGPoint(pt));
    
    CGFloat x = pt.x;
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat pct = x/w;
    int idx = (int)(self.locations.count*pct);
    if (idx > self.locations.count - 1) {
        _currentTouchPoint = CGPointZero;
        [self setNeedsDisplay];
        return;
    }
    EAILocation *l = self.locations[idx];
    int elevation = l.elevation;
    CGFloat y = [self yValueForLocation:l];
    NSLog(@"elev: %d", elevation);
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        _currentTouchPoint = CGPointZero;
    }
    else {
        _currentTouchPoint = CGPointMake(x, y);
    }
    [self setNeedsDisplay];
}

- (void)setLocations:(NSArray *)locations {
    _locations = locations;
    self.minValue = NSIntegerMax;
    self.maxValue = NSIntegerMin;
    for (EAILocation *l in _locations) {
        if (l.elevation > self.maxValue) {
            self.maxValue = l.elevation;
        }
        if (l.elevation < self.minValue) {
            self.minValue = l.elevation;
        }
    }
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    CGFloat h = CGRectGetHeight(self.bounds);
//    CGFloat w = CGRectGetWidth(self.bounds);
//
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGContextSetLineJoin(ctx, kCGLineJoinRound);
//    CGContextSetLineCap(ctx, kCGLineCapRound);
//    CGContextSetStrokeColorWithColor(ctx, [self.lineColor CGColor]);
//    CGContextSetLineWidth(ctx, self.lineWidth);
//    
//    CGFloat currX = CGRectGetMinX(self.bounds);
//    CGFloat currY = 0;
//    // Drawing code
//    int i = 0;
//    CGFloat step = w / self.locations.count;
//    for (EAILocation *location in self.locations) {
//        //
//        // UIKit has origin at top left, so whatever y we calculate needs to be flippped
//        // also we adjust max value by using 10% more than that so the high point is not at top of view
//        currY = h - (location.elevation / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
//        NSLog(@"currY: %f, elevation: %d", currY, location.elevation);
//        if (i == 0) {
//            CGContextMoveToPoint(ctx, currX, currY);
//            i++;
//        }
//        else {
//            CGContextAddLineToPoint(ctx, currX, currY);
//        }
//        currX += step;
//    }
//    CGContextStrokePath(ctx);
//    CGMutablePathRef pathCopy = CGPathCreateMutable();
////    CGContextMoveToPoint(ctx, currX, currY);
////    CGContextAddLineToPoint(ctx, w, h);
////    CGContextAddLineToPoint(ctx, 0, h);
//
//    CGContextSetFillColorWithColor(ctx, [[UIColor redColor] CGColor]);
//    CGContextFillPath(ctx);
////    CGContextDrawPath(ctx, kCGPathFillStroke);
////    CGContextDrawPath(ctx, kCGPathStroke);
//}

- (void)drawRect:(CGRect)rect
{
    CGFloat h = CGRectGetHeight(self.bounds);
    CGFloat w = CGRectGetWidth(self.bounds);
    
    CGMutablePathRef profilePath = CGPathCreateMutable();
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(ctx, [self.lineColor CGColor]);
    CGContextSetLineWidth(ctx, self.lineWidth);
    
    CGFloat currX = CGRectGetMinX(self.bounds);
    CGFloat currY = 0;
    // Drawing code
    int i = 0;
    CGFloat step = w / self.locations.count;
    for (EAILocation *location in self.locations) {
        //
        // UIKit has origin at top left, so whatever y we calculate needs to be flippped
        // also we adjust max value by using 10% more than that so the high point is not at top of view
        //currY = h - (location.elevation / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
        currY = [self yValueForLocation:location];
        //NSLog(@"currY: %f, elevation: %d", currY, location.elevation);
        if (i == 0) {
            CGPathMoveToPoint(profilePath, NULL, currX, currY);
            i++;
        }
        else {
            CGPathAddLineToPoint(profilePath, NULL, currX, currY);
        }
        currX += step;
    }

    //
    // create a copy that we can close to draw the area under the curve
    CGMutablePathRef pathCopy = CGPathCreateMutableCopy(profilePath);
    CGContextSetFillColorWithColor(ctx, [self.fillColor CGColor]);
    CGPathAddLineToPoint(pathCopy, NULL, w, h);
    CGPathAddLineToPoint(pathCopy, NULL, 0, h);
    CGContextAddPath(ctx, pathCopy);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(pathCopy);
    
    //
    // draw our top line in main color
    CGContextAddPath(ctx, profilePath);
    CGContextDrawPath(ctx, kCGPathStroke);
    CGPathRelease(profilePath);
    
    //
    // user is touching down
    if (!CGPointEqualToPoint(CGPointZero, _currentTouchPoint)) {
        CGContextSetFillColorWithColor(ctx, [[UIColor greenColor] CGColor]);
        CGContextFillEllipseInRect(ctx, CGRectMake(_currentTouchPoint.x - 5, _currentTouchPoint.y - 5, 10, 10));
    }
}

- (CGFloat)yValueForLocation:(EAILocation*)location {
    CGFloat h = CGRectGetHeight(self.bounds);
    return h - (location.elevation / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
}
@end
