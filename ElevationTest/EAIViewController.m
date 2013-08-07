//
//  EAIViewController.m
//  ElevationTest
//
//  Created by Eric Ito on 8/3/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAIViewController.h"
#import "EAIElevationTask.h"
#import "EAILocation.h"
#import "EAIElevationProfileView.h"
#import "EAIActivity.h"

@interface EAIViewController ()<CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate> {
    EAIElevationTask *_elevationTask;
    CLLocationManager *_locationManager;
    NSMutableArray *_locations;
    EAIElevationProfileView *_profileView;
    BOOL _deferringUpdates;
    
    BOOL _bg;
    BOOL _record;
    EAIActivity *_activity;
}

@end

@implementation EAIViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)goBG {
    _bg = YES;
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([CLLocationManager deferredLocationUpdatesAvailable] && !_deferringUpdates) {
        [_locationManager allowDeferredLocationUpdatesUntilTraveled:1000 timeout:600];
        _deferringUpdates = YES;
    }
}

- (void)goFG {
    _bg = NO;
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if ([CLLocationManager deferredLocationUpdatesAvailable]) {
        [_locationManager disallowDeferredLocationUpdates];
        _deferringUpdates = NO;
    }
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//      UIApplicationDidEnterBackgroundNotification
//      UIApplicationWillEnterForegroundNotification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goBG) name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goFG) name:@"UIApplicationWillEnterForegroundNotification" object:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dirPath = paths[0];
    NSString *filepath = [NSString stringWithFormat:@"%@/locations.json", dirPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        self.mapView.hidden = YES;
        NSData *data = [NSData dataWithContentsOfFile:filepath];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSArray *jsonArray = json[@"locations"];
        NSMutableArray *locations = [@[] mutableCopy];
        _activity = [EAIActivity activity];
        for (NSDictionary *d in jsonArray) {
            [locations addObject:[[EAILocation alloc] initWithJSON:d]];
        }
        [_activity addLocations:locations];
        
        _profileView = [[EAIElevationProfileView alloc] initWithFrame:CGRectMake(10, 320, 300, 160) locations:locations];
        _profileView.layer.borderColor = [[UIColor blackColor] CGColor];
        _profileView.layer.borderWidth = 2.0f;
        _profileView.backgroundColor = [UIColor whiteColor];
        _profileView.lineWidth = 3.0;
        _profileView.lineColor = [UIColor blueColor];
        _profileView.fillColor = [UIColor colorWithRed:0 green:120/255.0 blue:240/255.0 alpha:1.0];
        _profileView.minX = 0;
        _profileView.maxX = 320;
        _profileView.minY = 0;
        _profileView.maxY = 160;
        [self.view addSubview:_profileView];
        return;
    }

    self.mapView.hidden = YES;
//    [self.mapView showsUserLocation];
//    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.activityType = CLActivityTypeFitness;
    _locationManager.delegate = self;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    _locationManager.desiredAccuracy =  kCLLocationAccuracyBest;
    
    _elevationTask = [EAIElevationTask elevationTask];
    
    //
    // start now so we can get a fix
    [_locationManager startUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!_record) {
        return;
    }
    NSLog(@"Updated with %d locations %@", locations.count, locations);
    for (CLLocation *loc in locations) {
        EAILocation *eail = [[EAILocation alloc] initWithCLLocation:loc];
        [_activity addLocation:eail];
    }
    //[_locations addObjectsFromArray:locations];
    if (!_deferringUpdates && [CLLocationManager deferredLocationUpdatesAvailable]) {
        NSLog(@"DEFERRED UPDATES AVAILABLE");
        _deferringUpdates = YES;
        [_locationManager allowDeferredLocationUpdatesUntilTraveled:1000 timeout:600];
    }
    
    [self.tableView reloadData];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"======%s", __PRETTY_FUNCTION__);
}

-(void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    NSLog(@"Finished deferred updated: %@", error);
    _deferringUpdates = NO;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"+++%s", __PRETTY_FUNCTION__);
}

-(void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"+++%s", __PRETTY_FUNCTION__);
}

-(void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"+++%s", __PRETTY_FUNCTION__);
}

#pragma Actions

- (IBAction)startAction:(id)sender {
    _record = YES;
    _activity = [EAIActivity activity];
    
    //_locations = [@[] mutableCopy];
//    [_locationManager startUpdatingLocation];
}

- (IBAction)stopAction:(id)sender {
//    [_locationManager disallowDeferredLocationUpdates];
    //[_locationManager stopUpdatingLocation];
    _record = NO;
}

- (IBAction)exportLocations:(id)sender {
    //[_locationManager stopUpdatingLocation];
    
    __weak EAIViewController *weakSelf = self;
    __weak EAIActivity *weakActivity = _activity;
    _elevationTask.completionBlock = ^(NSArray *elevations, NSError *error) {
        [weakActivity recalculate];
        [weakSelf.tableView reloadData];
        NSLog(@"elevation count: %d", elevations.count);
        if (!error) {
            NSLog(@"elevations: %@", elevations);
            NSMutableDictionary *json = [@{} mutableCopy];
            NSMutableArray *locations = [@[] mutableCopy];
            for (EAILocation *loc in elevations) {
                [locations addObject:[loc encodeToJSON]];
            }
            json[@"locations"] = locations;
            
            NSTimeInterval nowSecs = [[NSDate date] timeIntervalSince1970];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *dirPath = paths[0];
            NSString *filepath = [NSString stringWithFormat:@"%@/%d.json", dirPath, (int)nowSecs];
            [[NSFileManager defaultManager] removeItemAtPath:filepath error:nil];
            NSOutputStream *outStream = [NSOutputStream outputStreamToFileAtPath:filepath append:NO];
            [outStream open];
            [NSJSONSerialization writeJSONObject:json
                                        toStream:outStream
                                         options:NSJSONWritingPrettyPrinted
                                           error:nil];
            [outStream close];
        }
        else {
            NSLog(@"error: %@", error);
        }
    };
    [_elevationTask findAstergdemElevationsForLocations:_activity.locations];
//    [_elevationTask findAstergdemElevationsForLocations:_locations];
}

#pragma mark UITableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // distance
    // climb (raw)
    // current elevation (raw)
    // climb (adjusted)
    // avg speed
    // curr speed
    return 7;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellid = @"cellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellid];
    }
    
    CGFloat totalDistanceInMiles = (_activity.totalDistance * 3.3) / 5280.0;
    CGFloat totalRawClimbInFeet = (_activity.totalRawClimb * 3.3);
    CGFloat currentAltitude = (_activity.currentAltitude * 3.3);
    CGFloat totalAdjClimb = (_activity.totalAdjustedClimb * 3.3);
    CGFloat avgSpeed = ((_activity.avgSpeed * 3.3) / 5280) * 3600;  //mph
    CGFloat currSpeed = ((_activity.currentSpeed * 3.3) / 5280) * 3600;  //mph
    
    switch (indexPath.row) {
        case 0: // distance
            cell.textLabel.text = @"Total Distance";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f miles", totalDistanceInMiles];
            break;
        case 1: // climb (raw)
            cell.textLabel.text = @"Total Climb (raw)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ft", totalRawClimbInFeet];
            break;
        case 2: // altitude (raw)
            cell.textLabel.text = @"Altitude (raw)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ft", currentAltitude];
            break;
        case 3: // climb (adjusted)
            cell.textLabel.text = @"Total Climb (adj)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ft", totalAdjClimb];
            break;
        case 4: // avg speed
            cell.textLabel.text = @"Avg Speed (m/s)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f mph", avgSpeed];
            break;
        case 5: // curr speed
            cell.textLabel.text = @"Current Speed (m/s)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f mph", currSpeed];
            break;
        case 6: // num data points
            cell.textLabel.text = @"# Points";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", _activity.locations.count];
            break;
    }
    return cell;
}
@end
