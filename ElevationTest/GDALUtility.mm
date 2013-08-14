//
//  GDALUtility.m
//  testgdal
//
//  Created by Eric Ito on 8/13/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "GDALUtility.h"

#include "gdal_priv.h"
//#include "cpl_conv.h"

static const NSString *kN34W117 = @"n34w117/grdn34w117_13/w001001.adf";
static const NSString *kN35W117 = @"n35w117/grdn35w117_13/w001001.adf";
static const NSString *kN34W118 = @"n34w118/grdn34w118_13/w001001.adf";
static const NSString *kN35W118 = @"n35w118/grdn35w118_13/w001001.adf";

@interface GDALUtility () {
    GDALDataset *_poDataset;
}

@end

@implementation GDALUtility

- (id)init
{
    self = [super init];
    if (self) {
        GDALAllRegister();
    }
    return self;
}

+ (instancetype)sharedUtility {
    return [[self alloc] init];
}

- (void)dealloc {
    if (_poDataset) {
        GDALClose(_poDataset);
    }
}

- (double)elevationForLatitude:(double)latitude longitude:(double)longitude {
    float elevation = -9999.0;
    NSString *filepath = [self filepathForLatitude:latitude longitude:longitude];
    _poDataset = (GDALDataset*)GDALOpen([filepath UTF8String], GA_ReadOnly);
    if (_poDataset) {
        double adfGeoTransform[6];
        if (_poDataset->GetGeoTransform(adfGeoTransform) == CE_None) {
            double x = longitude;
            double y = latitude;
            int rasterX = int((x - adfGeoTransform[0]) / adfGeoTransform[1]);
            int rasterY = int((y - adfGeoTransform[3]) / adfGeoTransform[5]);
            GDALRasterBand *band = _poDataset->GetRasterBand(1);
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
        GDALClose(_poDataset);
        _poDataset = NULL;
    }
    return elevation;
}

//- (NSString*)filenameFor

-(NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}

- (NSString*)filepathForLatitude:(double)latitude longitude:(double)longitude {
    NSString *docsDir = [self documentsDirectoryPath];
    if (longitude >= -118.0 && longitude < -117.0 &&
        latitude > 33.0 && latitude <= 34.0) {
        return [NSString stringWithFormat:@"%@/%@", docsDir, kN34W118];
    }
    else if (longitude >= -118.0 && longitude < -117.0 &&
             latitude > 34.0 && latitude <= 35.0) {
        return [NSString stringWithFormat:@"%@/%@", docsDir, kN35W118];
    }
    else if (longitude >= -117.0 && longitude < -116.0 &&
             latitude > 33.0 && latitude <= 34.0) {
        return [NSString stringWithFormat:@"%@/%@", docsDir, kN34W117];
    }
    else if (longitude >= -117.0 && longitude < -116.0 &&
             latitude > 34.0 && latitude <= 35.0) {
        return [NSString stringWithFormat:@"%@/%@", docsDir, kN35W117];
    }
    else {
        return nil;
    }
}
@end
