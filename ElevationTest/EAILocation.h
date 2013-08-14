//
//  EAILocation.h
//  ElevationTest
//
//  Created by Eric Ito on 8/3/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface EAILocation : NSObject<NSCoding>

- (id)initWithCLLocation:(CLLocation*)location;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                altitude:(CLLocationDistance)altitude
      horizontalAccuracy:(CLLocationAccuracy)hAccuracy
        verticalAccuracy:(CLLocationAccuracy)vAccuracy
                  course:(CLLocationDirection)course
                   speed:(CLLocationSpeed)speed
               timestamp:(NSDate *)timestamp
               elevation:(CGFloat)elevation;




@property (nonatomic, assign, readonly) double latitude;
@property (nonatomic, assign, readonly) double longitude;
@property (nonatomic, assign, readonly) double altitude;
@property (nonatomic, assign, readonly) double horizontalAccuracy;
@property (nonatomic, assign, readonly) double verticalAccuracy;
@property (nonatomic, assign, readonly) double course;
@property (nonatomic, assign, readonly) double speed;
@property (nonatomic, strong, readonly) NSDate *timestamp;

//
// readwrite so we can update this from the service
@property (nonatomic, assign, readwrite) CGFloat elevation;


- (id)initWithJSON:(NSDictionary*)json;
- (NSDictionary*)encodeToJSON;

- (double)distanceFromLocation:(EAILocation*)location;
@end
