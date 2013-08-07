//
//  EAIElevationTask.h
//  ElevationTest
//
//  Created by Eric Ito on 8/3/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface EAIElevationTask : NSObject

//
// default is 20, service free limit is also 20, premium is 2000
@property (nonatomic, assign) NSInteger batchSize;

@property (nonatomic, copy)  void (^completionBlock)(NSArray *elevations, NSError *error);

+(instancetype)elevationTask;

//
// pass in array of CLLocation objects
- (void)findSRTMElevationsForLocations:(NSArray*)locations;

//
// pass in array of CLLocation objects
- (void)findAstergdemElevationsForLocations:(NSArray*)locations;

- (void)cancel;
@end
