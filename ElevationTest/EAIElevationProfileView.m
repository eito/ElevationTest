//
//  EAIElevationProfileView.m
//  ElevationTest
//
//  Created by Eric Ito on 8/4/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAIElevationProfileView.h"
#import "EAILocation.h"

#if TARGET_OS_IPHONE
#define kRedrawWidth    10
#elif !TARGET_OS_IPHONE && TARGET_OS_MAC
#define kRedrawWidth    200
#endif

@interface EAIElevationProfileView ()
#if TARGET_OS_IPHONE
<UIGestureRecognizerDelegate>
#endif
{
    CGMutablePathRef _profilePath;
    CGMutablePathRef _fillPath;
    CGPoint _currentTouchPoint;
    CGFloat _currentTouchPointElevation;
#if TARGET_OS_IPHONE
    UILabel *_elevLabel;
#elif !TARGET_OS_IPHONE && TARGET_OS_MAC
    NSTextField *_elevLabel;
#endif
}

@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat maxValue;
#if TARGET_OS_IPHONE
@property (nonatomic, strong) UILongPressGestureRecognizer *tapHoldGR;
#endif
@end

@implementation EAIElevationProfileView

#if !TARGET_OS_IPHONE && TARGET_OS_MAC

//
// on OSX we flip the view so it behaves like iOS -- origin top left
- (BOOL)isFlipped {
    return YES;
}

//
// we also listen for bounds change to we redraw
// FIXME: this should be done a better way
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) {
        self.minX = 0;
        self.maxX = CGRectGetWidth([self bounds]);
        self.minY = 0;
        self.maxY = CGRectGetWidth([self bounds])/2;
        CGPathRelease(_profilePath);
        _profilePath = NULL;
        CGPathRelease(_fillPath);
        _fillPath = NULL;
        [self setNeedsDisplay:YES];
    }
}
#endif

- (id)initWithFrame:(CGRect)frame locations:(NSArray *)locations {
    self = [super initWithFrame:frame];
    if (self) {
        self.locations = locations;
        self.ceilingFactor = .1;
        self.lineColor = [EAIColor blueColor];
        self.fillColor = [EAIColor redColor];
        self.lineWidth = 3.0f;
        _currentTouchPoint = CGPointZero;
        _currentTouchPointElevation = -9999;
        self.displayElevationOnTapAndHold = YES;
        self.elevationTextColor = [EAIColor whiteColor];
        
        self.elevationCircleRadius = 10;
        self.elevationLineColor = [EAIColor greenColor];
        self.elevationLineWidth = 2.0;
        

        //
        // setup our elevation text
        CGFloat w = CGRectGetWidth(frame);
        CGFloat h = CGRectGetHeight(frame);

        CGRect textFrame = CGRectMake(w - 85, h - 20, 80, 20);
        
#if TARGET_OS_IPHONE
        _elevLabel = [[UILabel alloc] initWithFrame:textFrame];
        _elevLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        _elevLabel.textAlignment = NSTextAlignmentRight;
#elif !TARGET_OS_IPHONE && TARGET_OS_MAC
        _elevLabel = [[NSTextField alloc] initWithFrame:textFrame];
        _elevLabel.backgroundColor = [NSColor clearColor];
        _elevLabel.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;
        [_elevLabel setEditable:NO];
        [_elevLabel setSelectable:NO];
        [_elevLabel setBezeled:NO];
#endif
        _elevLabel.font = [EAIFont boldSystemFontOfSize:12];
        _elevLabel.textColor = self.elevationTextColor;
        [self addSubview:_elevLabel];

#if !TARGET_OS_IPHONE && TARGET_OS_MAC
        //
        // FIXME: do this a better way
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
#endif

    }
    return self;
}

- (void)setElevationTextColor:(EAIColor *)elevationTextColor {
    _elevationTextColor = elevationTextColor;
    _elevLabel.textColor = _elevationTextColor;
#if TARGET_OS_IPHONE
    [self setNeedsDisplay];
#else
    [self setNeedsDisplay:YES];
#endif
}

- (void)setDisplayElevationOnTapAndHold:(BOOL)displayElevationOnTapAndHold {
    _displayElevationOnTapAndHold = displayElevationOnTapAndHold;
#if TARGET_OS_IPHONE
    if (_displayElevationOnTapAndHold) {
        self.tapHoldGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapAndHold:)];
        self.tapHoldGR.delegate = self;
        [self addGestureRecognizer:self.tapHoldGR];
    }
    else {
        [self removeGestureRecognizer:self.tapHoldGR];
    }
#endif
}

#if TARGET_OS_IPHONE
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
    [attributedString addAttribute:NSForegroundColorAttributeName value:self.elevationTextColor range:NSMakeRange(0, [text length])];
    
    _elevLabel.attributedText=attributedString;

    //NSLog(@"elev: %d", elevation);
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        _elevLabel.hidden = YES;
        _currentTouchPoint = CGPointZero;
    }
    else {
        _elevLabel.hidden = NO;
        _currentTouchPoint = CGPointMake(x, y);
    }
    CGRect newRect = CGRectMake(_currentTouchPoint.x - 5, 0, 10, h);

    //
    // we only want to redraw the areas that have changed,
    // so union our old rect with our new rect
    [self setNeedsDisplayInRect:CGRectUnion(oldRect, newRect)];
}
#elif !TARGET_OS_IPHONE && TARGET_OS_MAC
//
//
-(void)updateViewForEvent:(NSEvent*)theEvent {
    NSPoint origPt = [theEvent locationInWindow];
    NSPoint convertedPt = [self convertPoint:origPt toView:self];
    _currentTouchPoint = convertedPt;
    CGFloat h = CGRectGetHeight(self.bounds);
    CGRect oldRect = CGRectMake(_currentTouchPoint.x - kRedrawWidth*.5, 0, kRedrawWidth, h);
    CGFloat x = convertedPt.x;
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat pct = x/w;
    int idx = (int)(self.locations.count*pct);
    if (idx > self.locations.count - 1) {
        _currentTouchPoint = CGPointZero;
        _currentTouchPointElevation = -9999;
        [self setNeedsDisplay:YES];
        return;
    }
    EAILocation *l = self.locations[idx];
    CGFloat y = [self yValueForLocation:l];
    int elevation = l.elevation;
    _currentTouchPointElevation = elevation * 3.28;
    
    //
    // update our elevation text
    NSString *text = [NSString stringWithFormat:@"%.2f ft", _currentTouchPointElevation];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-3.0] range:NSMakeRange(0,[text length])];
    [attributedString addAttribute:NSStrokeColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [text length])];
    [attributedString addAttribute:NSForegroundColorAttributeName value:self.elevationTextColor range:NSMakeRange(0, [text length])];
    [_elevLabel setAttributedStringValue:attributedString];
    
    
    //NSLog(@"elev: %d", elevation);
    
    _currentTouchPoint = CGPointMake(x, y);
    
    CGRect newRect = CGRectMake(_currentTouchPoint.x - kRedrawWidth*.5, 0, kRedrawWidth, h);
    
    //
    // we only want to redraw the areas that have changed,
    // so union our old rect with our new rect
    [self setNeedsDisplayInRect:CGRectUnion(oldRect, newRect)];
}

-(void)mouseDown:(NSEvent *)theEvent {
    [self updateViewForEvent:theEvent];
    
    _elevLabel.alphaValue = 1.0;
}

-(void)mouseDragged:(NSEvent *)theEvent {
    [self updateViewForEvent:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent {
    _currentTouchPoint = CGPointZero;
    _elevLabel.alphaValue = 0.0;
    [self setNeedsDisplay:YES];
}

#endif

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
    
#if TARGET_OS_IPHONE
    CGContextRef ctx = UIGraphicsGetCurrentContext();
#else
    [self lockFocus];
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [self unlockFocus];
#endif
    
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
        CGContextSetFillColorWithColor(ctx, [[EAIColor greenColor] CGColor]);
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
