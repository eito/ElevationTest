//
//  EAIActivity.h
//  ElevationTest
//
//  Created by Eric Ito on 8/7/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class EAILocation;

@interface EAIActivity : NSObject

+(instancetype)activity;

- (void)addLocation:(EAILocation*)location;
- (void)addLocations:(NSArray*)locations;

- (void)removeLocation:(EAILocation*)location;
- (void)removeLocations:(NSArray*)locations;
- (void)removeAllLocations;

@property (nonatomic, assign, readonly) CGFloat currentSpeed;
@property (nonatomic, assign, readonly) CGFloat currentAltitude;

@property (nonatomic, assign, readonly) CGFloat avgSpeed;

@property (nonatomic, assign, readonly) CGFloat totalRawClimb;
@property (nonatomic, assign, readonly) CGFloat totalAdjustedClimb;
@property (nonatomic, assign, readonly) CGFloat totalDistance;

@property (nonatomic, strong, readonly) NSArray *locations;

- (void)recalculate;

@end
