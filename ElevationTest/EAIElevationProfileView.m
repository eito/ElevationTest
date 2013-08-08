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
    CGFloat _currentTouchPointElevation;
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
        _currentTouchPoint = CGPointZero;
        _currentTouchPointElevation = -9999;
        self.displayElevationOnTapAndHold = YES;
        self.elevationTextColor = [UIColor whiteColor];
        
        self.elevationCircleRadius = 10;
        self.elevationLineColor = [UIColor greenColor];
        self.elevationLineWidth = 2.0;
    }
    return self;
}

- (void)setDisplayElevationOnTapAndHold:(BOOL)displayElevationOnTapAndHold {
    _displayElevationOnTapAndHold = displayElevationOnTapAndHold;
    if (_displayElevationOnTapAndHold) {
        self.tapHoldGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapAndHold:)];
        self.tapHoldGR.delegate = self;
        [self addGestureRecognizer:self.tapHoldGR];
    }
    else {
        [self removeGestureRecognizer:self.tapHoldGR];
    }
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
        _currentTouchPointElevation = -9999;
        [self setNeedsDisplay];
        return;
    }
    EAILocation *l = self.locations[idx];
    CGFloat y = [self yValueForLocation:l];
    int elevation = l.elevation;
    _currentTouchPointElevation = elevation * 3.3;
    //NSLog(@"elev: %d", elevation);
    
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
        CGContextFillEllipseInRect(ctx, CGRectMake(_currentTouchPoint.x - self.elevationCircleRadius/2, _currentTouchPoint.y - self.elevationCircleRadius/2, self.elevationCircleRadius, self.elevationCircleRadius));
        CGContextSetStrokeColorWithColor(ctx, [self.elevationLineColor CGColor]);
        CGContextSetLineWidth(ctx, self.elevationLineWidth);
        CGContextMoveToPoint(ctx, _currentTouchPoint.x, _currentTouchPoint.y);
        CGContextAddLineToPoint(ctx, _currentTouchPoint.x, h);
        CGContextStrokePath(ctx);
        //
        // text alignment for label
        NSMutableParagraphStyle *mutParaStyle=[[NSMutableParagraphStyle alloc] init];
        [mutParaStyle setAlignment:NSTextAlignmentRight];
        
        NSString *elevationString = [NSString stringWithFormat:@"%.2f ft", _currentTouchPointElevation];

        NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:elevationString
                                                                              attributes:@{ NSForegroundColorAttributeName : self.elevationTextColor, }];
        [s addAttribute:NSParagraphStyleAttributeName value:mutParaStyle range:NSMakeRange(0, [s length])];
        [s drawInRect:CGRectMake(w - 55, h - 20, 50, 20)];
    }
}

- (CGFloat)yValueForLocation:(EAILocation*)location {
    CGFloat h = CGRectGetHeight(self.bounds);
    return h - (location.elevation / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
}
@end
