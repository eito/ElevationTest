//
//  GDALUtility.m
//  testgdal
//
//  Created by Eric Ito on 8/13/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "GDALUtility.h"
#import "EAILocation.h"
#include "gdal_priv.h"
//#include "cpl_conv.h"

static const NSString *kN34W117 = @"n34w117/grdn34w117_13/w001001.adf";
static const NSString *kN35W117 = @"n35w117/grdn35w117_13/w001001.adf";
static const NSString *kN34W118 = @"n34w118/grdn34w118_13/w001001.adf";
static const NSString *kN35W118 = @"n35w118/grdn35w118_13/w001001.adf";


@interface GDALUtility () {
    NSMutableDictionary *_datasets;
    NSString *_documentsDirectory;
}

@end

@implementation GDALUtility

- (id)init
{
    self = [super init];
    if (self) {
        _datasets = [NSMutableDictionary dictionary];
        GDALAllRegister();
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _documentsDirectory = [paths objectAtIndex:0];
    }
    return self;
}

+ (instancetype)sharedUtility {
    static GDALUtility *kGDAL = nil;
    if (!kGDAL) {
        kGDAL = [[GDALUtility alloc] init];
    }
    return kGDAL;
}

- (void)dealloc {
    [_datasets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        GDALClose((__bridge GDALDataset*)obj);
    }];
}

- (void)calculateElevationsForLocations:(NSArray*)locations {
    for (EAILocation *l in locations) {
        l.elevation = [self elevationForLatitude:l.latitude longitude:l.longitude];
    }
}

- (double)elevationForLatitude:(double)latitude longitude:(double)longitude {
    float elevation = -9999.0;

    GDALDataset *gdalDataset = [self datasetForLatitude:latitude longitude:longitude];
    if (gdalDataset) {
        double adfGeoTransform[6];
        if (gdalDataset->GetGeoTransform(adfGeoTransform) == CE_None) {
            double x = longitude;
            double y = latitude;
            int rasterX = int((x - adfGeoTransform[0]) / adfGeoTransform[1]);
            int rasterY = int((y - adfGeoTransform[3]) / adfGeoTransform[5]);
            GDALRasterBand *band = gdalDataset->GetRasterBand(1);
            int nBlockXSize,nBlockYSize;
            band->GetBlockSize(&nBlockXSize, &nBlockYSize);
            double adfMinMax[2];
            adfMinMax[0] = band->GetMinimum();
            adfMinMax[1] = band->GetMaximum();
            // maybe need stuff here
            
            CPLErr err = band->RasterIO(GF_Read, rasterX, rasterY, 1, 1, &elevation, 1, 1, GDT_Float32, 0, 0);
            
            if (err == CE_None) {
                //NSLog(@"Success");
            }
        }
    }
    return elevation;
}

- (GDALDataset*)datasetForLatitude:(double)latitude longitude:(double)longitude {
    GDALDataset *gdalDataset = nil;
    NSString *key = nil;
    NSString *path = nil;
    
    if (longitude >= -118.0 && longitude < -117.0 &&
        latitude > 33.0 && latitude <= 34.0) {
        key = @"N34W118";
        path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, kN34W118];
    }
    else if (longitude >= -118.0 && longitude < -117.0 &&
             latitude > 34.0 && latitude <= 35.0) {
        key = @"N35W118";
        path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, kN35W118];
    }
    else if (longitude >= -117.0 && longitude < -116.0 &&
             latitude > 33.0 && latitude <= 34.0) {
        key = @"N34W117";
        path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, kN34W117];
    }
    else if (longitude >= -117.0 && longitude < -116.0 &&
             latitude > 34.0 && latitude <= 35.0) {
        key = @"N35W117";
        path = [NSString stringWithFormat:@"%@/%@", _documentsDirectory, kN35W117];
    }
    else {
        return nil;
    }
    
    gdalDataset = (GDALDataset*)[[_datasets valueForKey:key] pointerValue];
    if (!gdalDataset) {
        gdalDataset = (GDALDataset*)GDALOpen([path UTF8String], GA_ReadOnly);
        if (gdalDataset) {
            [_datasets setObject:[NSValue valueWithPointer:gdalDataset] forKey:key];
        }
    }
    return gdalDataset;
}
@end
