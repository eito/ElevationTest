//
//  EAISpeedProfileView.h
//  ElevationTest
//
//  Created by Eric Ito on 10/20/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAISpeedProfileView : UIView

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) CGFloat minY;
@property (nonatomic, assign) CGFloat maxY;
@property (nonatomic, assign) CGFloat minX;
@property (nonatomic, assign) CGFloat maxX;
@property (nonatomic, assign) CGFloat ceilingFactor;
//@property (nonatomic, assign) CGFloat floorFactor;
@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) UIColor *speedLineColor;
@property (nonatomic, assign) CGFloat speedLineWidth;
@property (nonatomic, assign) CGFloat speedCircleRadius;

@property (nonatomic, assign) BOOL displaySpeedOnTapAndHold;
@property (nonatomic, strong) UIColor *speedTextColor;

//
// array of EAILocation objects
- (id)initWithFrame:(CGRect)frame locations:(NSArray*)locations;

@end
