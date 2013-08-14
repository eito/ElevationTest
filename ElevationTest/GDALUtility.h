//
//  GDALUtility.h
//  testgdal
//
//  Created by Eric Ito on 8/13/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDALUtility : NSObject

- (double)elevationForLatitude:(double)latitude longitude:(double)longitude;

+ (instancetype)sharedUtility;
@end
