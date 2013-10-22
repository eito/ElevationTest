//
//  EAIElevationProfileView.h
//  ElevationTest
//
//  Created by Eric Ito on 8/4/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//



#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define EAIColor            UIColor
#define EAIFont             UIFont
#elif !TARGET_OS_IPHONE && TARGET_OS_MAC
#define EAIColor            NSColor
#define EAIFont             NSFont
#endif

@interface EAIElevationProfileView : UIView

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

@property (nonatomic, strong) EAIColor *elevationLineColor;
@property (nonatomic, assign) CGFloat elevationLineWidth;
@property (nonatomic, assign) CGFloat elevationCircleRadius;

@property (nonatomic, assign) BOOL displayElevationOnTapAndHold;
@property (nonatomic, strong) EAIColor *elevationTextColor;

//
// array of EAILocation objects
- (id)initWithFrame:(CGRect)frame locations:(NSArray*)locations;

@end
