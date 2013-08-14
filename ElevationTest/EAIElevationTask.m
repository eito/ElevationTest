//
//  EAIElevationTask.m
//  ElevationTest
//
//  Created by Eric Ito on 8/3/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAIElevationTask.h"
#import "AFNetworking/AFNetworking.h"
#import "EAILocation.h"

typedef enum {
    EAIElevationServiceTypeSRTM,
    EAIElevationServiceTypeAstergdem,
    EAIElevationServiceTypeGoogle
} EAIElevationServiceType;

@interface EAIElevationTask ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSMutableArray *operations;
@end
@implementation EAIElevationTask

- (id)init {
    self = [super init];
    if (self) {
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        self.batchSize = 20;
        self.results = [@[] mutableCopy];
        self.operations = [@[] mutableCopy];
        self.queue = [NSOperationQueue new];
        [self.queue setMaxConcurrentOperationCount:8];
    }
    return self;
}
+(instancetype)elevationTask {
    return [[self alloc] init];
}

//
// pass in array of CLLocation objects
- (void)findSRTMElevationsForLocations:(NSArray*)locations {
    [self kickoffOperationForLocations:locations serviceType:EAIElevationServiceTypeSRTM];
}

//
// pass in array of CLLocation objects
- (void)findAstergdemElevationsForLocations:(NSArray*)locations {
    [self kickoffOperationForLocations:locations serviceType:EAIElevationServiceTypeAstergdem];
}

//
// http://maps.googleapis.com/maps/api/elevation/json?path=36.578581,-118.291994|36.23998,-116.83171&samples=3&sensor=true
- (void)findGoogleElevationsForLocations:(NSArray *)locations {
    //[self kickoffOperationForLocations:locations serviceType:EAIElevationServiceTypeGoogle];
    
    [self cancel];
    
    // batch 512
//    self.batchSize = 100;
    
    [self.results addObjectsFromArray:locations];
    if (!locations.count) {
        return;
    }
    NSURL *url = [NSURL URLWithString:@"http://maps.googleapis.com/maps/api/elevation/json"];
    for (int i = 0; i < locations.count; i += self.batchSize) {
        NSInteger locationsRemaining = locations.count - i;
        NSInteger len = locationsRemaining > self.batchSize ? self.batchSize: locationsRemaining;
        NSRange range = NSMakeRange(i, len);
        NSArray *subArray = [locations subarrayWithRange:range];
//        NSURLRequest *req = [self elevationRequestForURL:url locations:subArray];
        NSURLRequest *req = [self elevationRequestForGoogleURL:url locations:subArray];
        __weak EAIElevationTask *weakSelf = self;
        AFJSONRequestOperation *jrop = [[AFJSONRequestOperation alloc] initWithRequest:req];
        [jrop setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            //            NSLog(@"operation %d done for items in range: %@", i, NSStringFromRange(range));
            
            //
            // update our results array with the new calculated elevations
            [weakSelf updateGoogleLocationsInRange:range withJSON:(NSDictionary*)responseObject];
            
            [weakSelf.operations removeObject:operation];
            if (weakSelf.operations.count == 0) {
                NSLog(@"OP QUEUE EMPTY=====");
                // done
                if (weakSelf.completionBlock) {
                    weakSelf.completionBlock(weakSelf.results, nil);
                }
            }
        }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        //
                                        // cancel
                                        [weakSelf cancel];
                                        //
                                        // if any one failed -- we fail for the whole thing
                                        if (weakSelf.completionBlock) {
                                            weakSelf.completionBlock(nil, error);
                                        }
                                    }];
        
        [self.operations addObject:jrop];
        [self.queue addOperation:jrop];
    }
}

- (void)cancel {
    [self.queue cancelAllOperations];
    [self.operations makeObjectsPerformSelector:@selector(cancel) withObject:nil];
    [self.operations removeAllObjects];
    [self.results removeAllObjects];
}

-(void)kickoffOperationForLocations:(NSArray*)locations
                                           serviceType:(EAIElevationServiceType)serviceType {
    //
    // cancel any current ops
    [self cancel];
    
    //
    // prime our results with input locations
    // converting them to EAILocations
//    for (CLLocation *location in locations) {
//        EAILocation *l = [[EAILocation alloc] initWithCLLocation:location];
//        [self.results addObject:l];
//    }
    // these are EAIlocations
    [self.results addObjectsFromArray:locations];
    
    if (!locations.count) {
        return;
    }
    NSURL *url = nil;
    if (serviceType == EAIElevationServiceTypeSRTM) {
        url = [NSURL URLWithString:@"http://ws.geonames.org/srtm3JSON"];
    }
    else {
        url = [NSURL URLWithString:@"http://ws.geonames.org/astergdemJSON"];
    }

    for (int i = 0; i < locations.count; i += self.batchSize) {
        NSInteger locationsRemaining = locations.count - i;
        NSInteger len = locationsRemaining > self.batchSize ? self.batchSize: locationsRemaining;
        NSRange range = NSMakeRange(i, len);
        NSArray *subArray = [locations subarrayWithRange:range];
        NSURLRequest *req = [self elevationRequestForURL:url locations:subArray];
        __weak EAIElevationTask *weakSelf = self;
        AFJSONRequestOperation *jrop = [[AFJSONRequestOperation alloc] initWithRequest:req];
        [jrop setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSLog(@"operation %d done for items in range: %@", i, NSStringFromRange(range));
            
            //
            // update our results array with the new calculated elevations
            [weakSelf updateLocationsInRange:range withJSON:(NSDictionary*)responseObject];
            
            [weakSelf.operations removeObject:operation];
            if (weakSelf.operations.count == 0) {
                NSLog(@"OP QUEUE EMPTY=====");
                // done
                if (weakSelf.completionBlock) {
                    weakSelf.completionBlock(weakSelf.results, nil);
                }
            }
        }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        //
                                        // cancel
                                        [weakSelf cancel];
                                        //
                                        // if any one failed -- we fail for the whole thing
                                        if (weakSelf.completionBlock) {
                                            weakSelf.completionBlock(nil, error);
                                        }
                                    }];

        [self.operations addObject:jrop];
        [self.queue addOperation:jrop];
    }
}

- (void)updateGoogleLocationsInRange:(NSRange)range withJSON:(NSDictionary*)json {
/*
 {
 "results" : [
 {
 "elevation" : 4411.941894531250,
 "location" : {
 "lat" : 36.5785810,
 "lng" : -118.2919940
 },
 "resolution" : 19.08790397644043
 },
 {
 "elevation" : -84.61699676513672,
 "location" : {
 "lat" : 36.239980,
 "lng" : -116.831710
 },
 "resolution" : 19.08790397644043
 }
 ],
 "status" : "OK"
 }
 */
    NSArray *itemsInRange = [self.results subarrayWithRange:range];
    NSArray *resultsJson = json[@"results"];
    NSInteger i = 0;
    for (NSDictionary *resultJson in resultsJson) {
        EAILocation *location = itemsInRange[i];
        location.elevation = (int)([resultJson[@"elevation"] doubleValue]);
        i++;
    }
}

- (void)updateLocationsInRange:(NSRange)range withJSON:(NSDictionary*)json {
    NSArray *itemsInRange = [self.results subarrayWithRange:range];
    NSArray *resultsJson = json[@"geonames"];
    NSInteger i = 0;
    for (NSDictionary *resultJson in resultsJson) {
        EAILocation *location = itemsInRange[i];
        if (resultJson[@"srtm3"]) {
            location.elevation = [resultJson[@"srtm3"] integerValue];
        }
        else {
            location.elevation = [resultJson[@"astergdem"] integerValue];
        }
        i++;
    }
}

- (NSURLRequest*)elevationRequestForGoogleURL:(NSURL*)url locations:(NSArray*)locations {
    //?path=36.578581,-118.291994|36.23998,-116.83171&samples=3&sensor=true
    
    NSMutableString *queryString = [[NSMutableString alloc] initWithString:@"path="];
    NSInteger i = 0;
    for (EAILocation *location in locations) {
        if (i++ == 0) {
            [queryString appendFormat:@"%f,%f", location.latitude, location.longitude];
        }
        else {
            [queryString appendFormat:@"|%f,%f", location.latitude, location.longitude];
        }
    }
    [queryString appendFormat:@"&samples=%u&sensor=true", locations.count];
    
    //NSString *urlString = [NSString stringWithFormat:@"%@?%@", [url absoluteString], queryString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPBody:[queryString dataUsingEncoding:NSUTF8StringEncoding]];
    return req;
}

- (NSURLRequest*)elevationRequestForURL:(NSURL*)url locations:(NSArray*)locations {
    NSMutableArray *lats = [@[] mutableCopy];
    NSMutableArray *lngs = [@[] mutableCopy];

    for (EAILocation *location in locations) {
        [lats addObject:@(location.latitude)];
        [lngs addObject:@(location.longitude)];
    }

//    for (CLLocation *location in locations) {
//        [lats addObject:@(location.coordinate.latitude)];
//        [lngs addObject:@(location.coordinate.longitude)];
//    }
    
    NSString *latsString = [lats componentsJoinedByString:@","];
    NSString *lngsString = [lngs componentsJoinedByString:@","];
    
    NSString *queryString = [NSString stringWithFormat:@"lats=%@&lngs=%@", latsString, lngsString];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPBody:[queryString dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPMethod:@"POST"];
    
    return req;
}
@end
