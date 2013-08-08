//
//  EAIElevationProfileView.h
//  ElevationTest
//
//  Created by Eric Ito on 8/4/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAIElevationProfileView : UIView

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

@property (nonatomic, strong) UIColor *elevationLineColor;
@property (nonatomic, assign) CGFloat elevationLineWidth;
@property (nonatomic, assign) CGFloat elevationCircleRadius;

@property (nonatomic, assign) BOOL displayElevationOnTapAndHold;
@property (nonatomic, strong) UIColor *elevationTextColor;

//
// array of EAILocation objects
- (id)initWithFrame:(CGRect)frame locations:(NSArray*)locations;

@end
