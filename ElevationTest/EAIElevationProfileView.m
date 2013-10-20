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
    UILabel *_elevLabel;
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
        
        //
        // setup our elevation text
        CGFloat w = CGRectGetWidth(frame);
        CGFloat h = CGRectGetHeight(frame);
        _elevLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 85, h - 20, 80, 20)];
        _elevLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        _elevLabel.textColor = self.elevationTextColor;
        _elevLabel.font = [UIFont boldSystemFontOfSize:12];
        _elevLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_elevLabel];
    }
    return self;
}

- (void)setElevationTextColor:(UIColor *)elevationTextColor {
    _elevationTextColor = elevationTextColor;
    _elevLabel.textColor = _elevationTextColor;
    [self setNeedsDisplay];
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
    
    CGFloat h = CGRectGetHeight(self.bounds);
    CGRect oldRect = CGRectMake(_currentTouchPoint.x - 5, 0, 10, h);
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
    _currentTouchPointElevation = elevation * 3.28;

    //
    // update our elevation text
    //_elevLabel.text = [NSString stringWithFormat:@"%.2f ft", _currentTouchPointElevation];
    NSString *text = [NSString stringWithFormat:@"%.2f ft", _currentTouchPointElevation];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0,[text length])];
    [attributedString addAttribute:NSStrokeColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [text length])];
    
    _elevLabel.attributedText=attributedString;

    //NSLog(@"elev: %d", elevation);
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        _currentTouchPoint = CGPointZero;
    }
    else {
        _currentTouchPoint = CGPointMake(x, y);
    }
    CGRect newRect = CGRectMake(_currentTouchPoint.x - 5, 0, 10, h);

    //
    // we only want to redraw the areas that have changed,
    // so union our old rect with our new rect
    [self setNeedsDisplayInRect:CGRectUnion(oldRect, newRect)];
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

- (CGMutablePathRef)fillPathForContext:(CGContextRef)ctx {
    if (!_fillPath) {
        CGFloat h = CGRectGetHeight(self.bounds);
        CGFloat w = CGRectGetWidth(self.bounds);
        
        _fillPath = CGPathCreateMutableCopy([self profilePath]);
        //
        // create a copy that we can close to draw the area under the curve
        CGPathAddLineToPoint(_fillPath, NULL, w, h);
        CGPathAddLineToPoint(_fillPath, NULL, 0, h);
    }
    return _fillPath;
}

- (CGMutablePathRef)profilePath {
    if (!_profilePath) {
        _profilePath = CGPathCreateMutable();
        CGFloat currX = CGRectGetMinX(self.bounds);
        CGFloat currY = 0;
        CGFloat w = CGRectGetWidth(self.bounds);
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
                CGPathMoveToPoint(_profilePath, NULL, currX, currY);
                i++;
            }
            else {
                CGPathAddLineToPoint(_profilePath, NULL, currX, currY);
            }
            currX += step;
        }
    }
    return _profilePath;
}

- (void)dealloc {
    if (_profilePath) {
        CGPathRelease(_profilePath);
    }
    if (_fillPath) {
        CGPathRelease(_fillPath);
    }
}

//
// caches PATHs
- (void)drawRect:(CGRect)rect
{
    CGFloat h = CGRectGetHeight(self.bounds);
//    CGFloat w = CGRectGetWidth(self.bounds);
    
    CGMutablePathRef profilePath = [self profilePath];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(ctx, [self.lineColor CGColor]);
    CGContextSetLineWidth(ctx, self.lineWidth);
    
    //
    // create a copy that we can close to draw the area under the curve
    CGMutablePathRef pathCopy = [self fillPathForContext:ctx];
    CGContextSetFillColorWithColor(ctx, [self.fillColor CGColor]);
    CGContextAddPath(ctx, pathCopy);
    CGContextDrawPath(ctx, kCGPathFill);
//    CGPathRelease(pathCopy);
    
    //
    // draw our top line in main color
    CGContextAddPath(ctx, profilePath);
    CGContextDrawPath(ctx, kCGPathStroke);
//    CGPathRelease(profilePath);
    
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
    }
}


- (CGFloat)yValueForLocation:(EAILocation*)location {
    CGFloat h = CGRectGetHeight(self.bounds);
    return h - (location.elevation / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
}
@end
