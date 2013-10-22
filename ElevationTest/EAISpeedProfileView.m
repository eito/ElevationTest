//
//  EAISpeedProfileView.m
//  ElevationTest
//
//  Created by Eric Ito on 10/20/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAISpeedProfileView.h"
#import "EAILocation.h"

const double kMPS_to_MPH=2.23694;

@interface EAISpeedProfileView ()<UIGestureRecognizerDelegate> {
    CGMutablePathRef _profilePath;
    CGMutablePathRef _fillPath;
    CGPoint _currentTouchPoint;
    CGFloat _currentTouchPointSpeed;
    UILabel *_speedLabel;
}

@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat maxValue;
@property (nonatomic, strong) UILongPressGestureRecognizer *tapHoldGR;
@end

@implementation EAISpeedProfileView

- (id)initWithFrame:(CGRect)frame locations:(NSArray *)locations {
    self = [super initWithFrame:frame];
    if (self) {
        self.locations = locations;
        self.ceilingFactor = .1;
        self.lineColor = [UIColor blueColor];
        self.fillColor = [UIColor redColor];
        self.lineWidth = 3.0f;
        _currentTouchPoint = CGPointZero;
        _currentTouchPointSpeed = -1;
        self.displaySpeedOnTapAndHold = YES;
        self.speedTextColor = [UIColor whiteColor];
        
        self.speedCircleRadius = 10;
        self.speedLineColor = [UIColor greenColor];
        self.speedLineWidth = 2.0;
        
        //
        // setup our speed text
        CGFloat w = CGRectGetWidth(frame);
        CGFloat h = CGRectGetHeight(frame);
        _speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 85, h - 20, 80, 20)];
        _speedLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        _speedLabel.textColor = self.speedTextColor;
        _speedLabel.font = [UIFont boldSystemFontOfSize:12];
        _speedLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_speedLabel];
    }
    return self;
}

- (void)setSpeedTextColor:(UIColor *)speedTextColor {
    _speedTextColor = speedTextColor;
    _speedLabel.textColor = _speedTextColor;
    [self setNeedsDisplay];
}

- (void)setDisplaySpeedOnTapAndHold:(BOOL)displaySpeedOnTapAndHold {
    _displaySpeedOnTapAndHold = displaySpeedOnTapAndHold;
    if (_displaySpeedOnTapAndHold) {
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
        _currentTouchPointSpeed = -1;
        [self setNeedsDisplay];
        return;
    }
    EAILocation *l = self.locations[idx];
    CGFloat y = [self yValueForLocation:l];
    int speed = l.speed;
    _currentTouchPointSpeed = speed * kMPS_to_MPH;
    
    //
    // update our speed text
    NSString *text = [NSString stringWithFormat:@"%.2f mph", _currentTouchPointSpeed];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0,[text length])];
    [attributedString addAttribute:NSStrokeColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attributedString addAttribute:NSForegroundColorAttributeName value:self.speedTextColor range:NSMakeRange(0, [text length])];    
    _speedLabel.attributedText=attributedString;
    
//    _speedLabel.text = [NSString stringWithFormat:@"%.2f mph", _currentTouchPointSpeed];
    //NSLog(@"speed: %d", speed);
    
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
        double s = l.speed * kMPS_to_MPH;
        if (s > self.maxValue) {
            self.maxValue = s;
        }
        if (s < self.minValue) {
            self.minValue = s;
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
            //currY = h - (location.speed / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
            currY = [self yValueForLocation:location];
            //NSLog(@"currY: %f, speed: %d", currY, location.speed);
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
        CGContextFillEllipseInRect(ctx, CGRectMake(_currentTouchPoint.x - self.speedCircleRadius/2, _currentTouchPoint.y - self.speedCircleRadius/2, self.speedCircleRadius, self.speedCircleRadius));
        CGContextSetStrokeColorWithColor(ctx, [self.speedLineColor CGColor]);
        CGContextSetLineWidth(ctx, self.speedLineWidth);
        CGContextMoveToPoint(ctx, _currentTouchPoint.x, _currentTouchPoint.y);
        CGContextAddLineToPoint(ctx, _currentTouchPoint.x, h);
        CGContextStrokePath(ctx);
    }
}


- (CGFloat)yValueForLocation:(EAILocation*)location {
    CGFloat h = CGRectGetHeight(self.bounds);
    return h - (location.speed * kMPS_to_MPH / (self.maxValue*(1+self.ceilingFactor) - self.minY)) * h;
}
@end
