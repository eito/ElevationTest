//
//  EAISpeedProfileView.h
//  ElevationTest
//
//  Created by Eric Ito on 10/20/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define EAIColor            UIColor
#define EAIFont             UIFont
#define EAIView             UIView
#elif !TARGET_OS_IPHONE && TARGET_OS_MAC
#define EAIColor            NSColor
#define EAIFont             NSFont
#define EAIView             NSView
#endif

@interface EAISpeedProfileView : EAIView

@property (nonatomic, strong) EAIColor *lineColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) EAIColor *fillColor;
@property (nonatomic, assign) CGFloat minY;
@property (nonatomic, assign) CGFloat maxY;
@property (nonatomic, assign) CGFloat minX;
@property (nonatomic, assign) CGFloat maxX;
@property (nonatomic, assign) CGFloat ceilingFactor;
//@property (nonatomic, assign) CGFloat floorFactor;
@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) EAIColor *speedLineColor;
@property (nonatomic, assign) CGFloat speedLineWidth;
@property (nonatomic, assign) CGFloat speedCircleRadius;

@property (nonatomic, assign) BOOL displaySpeedOnTapAndHold;
@property (nonatomic, strong) EAIColor *speedTextColor;

//
// array of EAILocation objects
- (id)initWithFrame:(CGRect)frame locations:(NSArray*)locations;

@end
