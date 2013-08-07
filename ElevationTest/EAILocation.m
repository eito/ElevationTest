//
//  EAILocation.m
//  ElevationTest
//
//  Created by Eric Ito on 8/3/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAILocation.h"

@interface EAILocation () {
    BOOL _srtm;
    CLLocation *_cllocation;
}
@end

@implementation EAILocation

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _cllocation = [aDecoder decodeObjectForKey:@"cllocation"];
        self.elevation = [aDecoder decodeIntegerForKey:@"elevation"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_cllocation forKey:@"cllocation"];
    [aCoder encodeInteger:self.elevation forKey:@"elevation"];
}

/*
 {
 lat = 34;
 lng = "-117";
 srtm3 = 1027;
 }
 */

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                altitude:(CLLocationDistance)altitude
      horizontalAccuracy:(CLLocationAccuracy)hAccuracy
        verticalAccuracy:(CLLocationAccuracy)vAccuracy
                  course:(CLLocationDirection)course
                   speed:(CLLocationSpeed)speed
               timestamp:(NSDate *)timestamp
               elevation:(double)elevation {
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coordinate
                                                    altitude:altitude
                                          horizontalAccuracy:hAccuracy
                                            verticalAccuracy:vAccuracy
                                                      course:course
                                                       speed:speed
                                                   timestamp:timestamp];
    self = [self initWithCLLocation:loc];
    if (self) {
        self.elevation = elevation;
    }
    return self;
}

- (id)initWithCLLocation:(CLLocation*)location {
    self = [super init];
    if (self) {
        _cllocation = location;
    }
    return self;
}


- (NSString*)description {
    NSString *clloc = [_cllocation description];
    return [NSString stringWithFormat:@"calc elev: %dm, %@", self.elevation, clloc];
}

- (double)distanceFromLocation:(EAILocation*)location {
    if (!location) {
        return 0;
    }
    return [_cllocation distanceFromLocation:location->_cllocation];
}

#pragma mark Getters

- (double)latitude {
    return _cllocation.coordinate.latitude;
}

- (double)longitude {
    return _cllocation.coordinate.longitude;
}

- (double)altitude {
    return _cllocation.altitude;
}

- (double)horizontalAccuracy {
    return _cllocation.horizontalAccuracy;
}

- (double)verticalAccuracy {
    return _cllocation.verticalAccuracy;
}

- (double)course {
    return _cllocation.course;
}

- (NSDate*)timestamp {
    return _cllocation.timestamp;
}

- (double)speed {
    return _cllocation.speed;
}

#pragma mark JSON encoding

//-(id)initWithJSON:(NSDictionary *)json{
//    self = [super init];
//    if (self) {
//        double latitude = [json[@"lat"] doubleValue];
//        double longitude = [json[@"lng"] doubleValue];
//        if (json[@"srtm3"]) {
//            self.elevation = [json[@"srtm3"] integerValue];
//            _srtm = YES;
//        }
//        else {
//            self.elevation = [json[@"astergdem"] integerValue];
//        }
//    }
//    return self;
//}
//
//- (NSDictionary*)encodeToJSON {
//    NSMutableDictionary *json = [@{} mutableCopy];
//    if (_srtm) {
//        json[@"srtm3"] = @(self.elevation);
//    }
//    else  {
//        json[@"astergdem"] = @(self.elevation);
//    }
//    
//    json[@"lat"] = @(self.latitude);
//    json[@"lng"] = @(self.longitude);
//    return json;
//}
-(id)initWithJSON:(NSDictionary *)json{

    double latitude = [json[@"latitude"] doubleValue];
    double longitude = [json[@"longitude"] doubleValue];
    double vAccuracy = [json[@"vAccuracy"] doubleValue];
    double hAccuracy = [json[@"hAccuracy"] doubleValue];
    double speed = [json[@"speed"] doubleValue];
    double course = [json[@"course"] doubleValue];
    double altitude = [json[@"altitude"] doubleValue];
    double secSinceEpoch = [json[@"timestamp"] doubleValue];
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:secSinceEpoch];
    double elevation = [json[@"elevation"] integerValue];
    
    return [self initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                           altitude:altitude
                 horizontalAccuracy:hAccuracy
                   verticalAccuracy:vAccuracy
                             course:course
                              speed:speed
                          timestamp:timestamp
                          elevation:elevation];
}

- (NSDictionary*)encodeToJSON {
    NSMutableDictionary *json = [@{} mutableCopy];
    json[@"latitude"] = @(self.latitude);
    json[@"longitude"] = @(self.longitude);
    json[@"vAccuracy"] = @(self.verticalAccuracy);
    json[@"hAccuracy"] = @(self.horizontalAccuracy);
    json[@"speed"] = @(self.speed);
    json[@"course"] = @(self.course);
    json[@"altitude"] = @(self.altitude);
    json[@"timestamp"] = @([self.timestamp timeIntervalSince1970]);
    json[@"elevation"] = @(self.elevation);
    return json;
}

@end
