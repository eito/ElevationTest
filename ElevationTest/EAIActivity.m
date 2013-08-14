//
//  EAIActivity.m
//  ElevationTest
//
//  Created by Eric Ito on 8/7/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAIActivity.h"
#import "EAILocation.h"

@interface EAIActivity () {
    NSMutableArray *_locations;
}
@property (nonatomic, assign, readwrite) CGFloat currentSpeed;
@property (nonatomic, assign, readwrite) CGFloat currentAltitude;
@property (nonatomic, assign, readwrite) CGFloat avgSpeed;
@property (nonatomic, assign, readwrite) CGFloat totalRawClimb;
@property (nonatomic, assign, readwrite) CGFloat totalAdjustedClimb;
@property (nonatomic, assign, readwrite) CGFloat totalDistance;
//@property (nonatomic, strong, readwrite) NSMutableArray *locations;
@end

@implementation EAIActivity

- (id)init {
    self = [super init];
    if (self) {
        _locations = [@[] mutableCopy];
    }
    return self;
}

+(instancetype)activity {
    return [[self alloc] init];
}

- (void)addLocation:(EAILocation*)location {
    // TODO: dont add location if same coordinate as last
    [self addLocations:@[location]];
}

- (void)addLocations:(NSArray*)locations {
    EAILocation *lastLoc = nil;
    for (EAILocation *location in locations) {
        CGFloat climb = 0;
        CGFloat adjClimb = 0;
        if (lastLoc) {
            climb = location.altitude - lastLoc.altitude;
            adjClimb = location.elevation - lastLoc.elevation;
        }
        if (climb > 0) {
            self.totalRawClimb += climb;
        }
        if (adjClimb > 0) {
            self.totalAdjustedClimb += adjClimb;
        }
        
        self.currentAltitude = location.altitude;
        self.currentSpeed = location.speed;
        if (lastLoc) {
            //NSLog(@"dist: %f", [location distanceFromLocation:lastLoc]);
            self.totalDistance += [location distanceFromLocation:lastLoc];
        }
        self.avgSpeed = ((self.avgSpeed * self.locations.count) + location.speed) / (self.locations.count + 1);
        
        [_locations addObject:location];
        lastLoc = location;
    }
}

- (void)removeLocation:(EAILocation*)location {
    [_locations removeObject:location];
}

- (void)removeLocations:(NSArray*)locations {
    [_locations removeObjectsInArray:locations];
}

- (void)removeAllLocations {
    [_locations removeAllObjects];
}

- (void)recalculate {
    if (!_locations.count) {
        return;
    }
    
    CGFloat alt = 0;
    CGFloat rawClimb = 0;
    CGFloat adjClimb = 0;
    CGFloat distance = 0;
    CGFloat speedSum = 0;
    CGFloat currSpeed = 0;
    
    EAILocation *lastLoc = nil;
    rawClimb = 0;
    adjClimb = 0;
    for (EAILocation *l in _locations) {
        CGFloat climb = 0;
        CGFloat adj = 0;
        if (lastLoc) {
            climb = l.altitude - lastLoc.altitude;
            adj = l.elevation - lastLoc.elevation;
        }
        if (climb > 0) {
            rawClimb += climb;
        }
        
        if (adj > 0) {
            adjClimb += adj;
        }
        
        alt = l.altitude;
        currSpeed = l.speed;
        if (lastLoc) {
            distance += [l distanceFromLocation:lastLoc];
        }
        speedSum += l.speed;
        lastLoc = l;
    }
    self.currentAltitude = alt;
    self.currentSpeed = currSpeed;
    self.totalDistance = distance;
    self.totalRawClimb = rawClimb;
    self.totalAdjustedClimb = adjClimb;
    self.avgSpeed = speedSum / _locations.count;
}

@end
