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
#import "EAISpeedProfileView.h"
#import "EAIActivity.h"
#import "PopoverView.h"
#import "EAIActivityListViewController.h"

@interface EAIViewController ()<CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, PopoverViewDelegate> {
    EAIElevationTask *_elevationTask;
    CLLocationManager *_locationManager;
    NSMutableArray *_locations;
    EAIElevationProfileView *_profileView;
    EAISpeedProfileView *_speedView;
    BOOL _deferringUpdates;
    
    BOOL _bg;
    BOOL _record;
    EAIActivity *_activity;
    MKPolylineView *_currentActivityView;
    MKMapRect _currentActivityBBox;
    PopoverView *_popover;
    NSMutableArray *_activityFiles;
    EAIActivityListViewController *_activityListVC;
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

- (void)loadDataForActivityAtURL:(NSURL*)fileURL {
    [_locationManager stopUpdatingLocation];
    
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *jsonArray = json[@"locations"];
    NSMutableArray *locations = [@[] mutableCopy];
    _activity = [EAIActivity activity];
    for (NSDictionary *d in jsonArray) {
        [locations addObject:[[EAILocation alloc] initWithJSON:d]];
    }
    [_activity addLocations:locations];
    
    [self.tableView reloadData];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [_profileView removeFromSuperview];
    _profileView = [[EAIElevationProfileView alloc] initWithFrame:CGRectMake(5, 20, 310, 180) locations:locations];
    _profileView.hidden = YES;
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
    
    [_speedView removeFromSuperview];
    _speedView = [[EAISpeedProfileView alloc] initWithFrame:CGRectMake(5, 20, 310, 180) locations:locations];
    _speedView.hidden = YES;
    _speedView.layer.borderColor = [[UIColor blackColor] CGColor];
    _speedView.layer.borderWidth = 2.0f;
    _speedView.backgroundColor = [UIColor whiteColor];
    _speedView.lineWidth = 3.0;
    _speedView.lineColor = [UIColor blueColor];
    _speedView.fillColor = [UIColor colorWithRed:0 green:120/255.0 blue:240/255.0 alpha:1.0];
    _speedView.minX = 0;
    _speedView.maxX = 320;
    _speedView.minY = 0;
    _speedView.maxY = 160;
    [self.view addSubview:_speedView];
    
    //
    // add line
    CLLocationCoordinate2D *coordinateArray = malloc(sizeof(CLLocationCoordinate2D) * _activity.locations.count);
    
    int caIndex = 0;
    double xmin = 0;
    double xmax = 0;
    double ymin = 0;
    double ymax = 0;
    for (EAILocation *loc in _activity.locations) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(loc.latitude, loc.longitude);
        coordinateArray[caIndex] = coord;
        MKMapPoint pt = MKMapPointForCoordinate(coord);
        if (caIndex == 0) {
            xmin = pt.x;
            xmax = pt.x;
            ymin = pt.y;
            ymax = pt.y;
        }
        else {
            if (pt.y < ymin) {
                ymin = pt.y;
            }
            if (pt.y > ymax) {
                ymax = pt.y;
            }
            if (pt.x < xmin) {
                xmin = pt.x;
            }
            if (pt.x > xmax) {
                xmax = pt.x;
            }
        }
        caIndex++;
    }
    _currentActivityBBox = MKMapRectMake(xmin, ymin, xmax - xmin, ymax - ymin);
    MKPolyline *lines = [MKPolyline polylineWithCoordinates:coordinateArray
                                                      count:_activity.locations.count];
    
    [self.mapView addOverlay:lines];
    [self.mapView setVisibleMapRect:_currentActivityBBox animated:YES];
    free(coordinateArray);
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
    
    self.mapView.delegate = self;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        NSURL *url = [NSURL fileURLWithPath:filepath];
        [self loadDataForActivityAtURL:url];
//        NSData *data = [NSData dataWithContentsOfFile:filepath];
//        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
//        NSArray *jsonArray = json[@"locations"];
//        NSMutableArray *locations = [@[] mutableCopy];
//        _activity = [EAIActivity activity];
//        for (NSDictionary *d in jsonArray) {
//            [locations addObject:[[EAILocation alloc] initWithJSON:d]];
//        }
//        [_activity addLocations:locations];
//        
//        _profileView = [[EAIElevationProfileView alloc] initWithFrame:CGRectMake(5, 20, 310, 180) locations:locations];
//        _profileView.hidden = YES;
//        _profileView.layer.borderColor = [[UIColor blackColor] CGColor];
//        _profileView.layer.borderWidth = 2.0f;
//        _profileView.backgroundColor = [UIColor whiteColor];
//        _profileView.lineWidth = 3.0;
//        _profileView.lineColor = [UIColor blueColor];
//        _profileView.fillColor = [UIColor colorWithRed:0 green:120/255.0 blue:240/255.0 alpha:1.0];
//        _profileView.minX = 0;
//        _profileView.maxX = 320;
//        _profileView.minY = 0;
//        _profileView.maxY = 160;
//        [self.view addSubview:_profileView];
//        
//        //
//        // add line
//        CLLocationCoordinate2D *coordinateArray = malloc(sizeof(CLLocationCoordinate2D) * _activity.locations.count);
//        
//        int caIndex = 0;
//        double xmin = 0;
//        double xmax = 0;
//        double ymin = 0;
//        double ymax = 0;
//        for (EAILocation *loc in _activity.locations) {
//            coordinateArray[caIndex] = CLLocationCoordinate2DMake(loc.latitude, loc.longitude);
//            MKMapPoint pt = MKMapPointForCoordinate(CLLocationCoordinate2DMake(loc.latitude, loc.longitude));
//            if (caIndex == 0) {
//                xmin = pt.x;
//                xmax = pt.x;
//                ymin = pt.y;
//                ymax = pt.y;
//            }
//            else {
//                if (pt.y < ymin) {
//                    ymin = pt.y;
//                }
//                if (pt.y > ymax) {
//                    ymax = pt.y;
//                }
//                if (pt.x < xmin) {
//                    xmin = pt.x;
//                }
//                if (pt.x > xmax) {
//                    xmax = pt.x;
//                }
//            }
//            caIndex++;
//        }
//        _currentActivityBBox = MKMapRectMake(xmin, ymin, xmax - xmin, ymax - ymin);
//        MKPolyline *lines = [MKPolyline polylineWithCoordinates:coordinateArray
//                                                          count:_activity.locations.count];
//
//        free(coordinateArray);
//        [self.mapView addOverlay:lines];
//        [self.mapView setVisibleMapRect:_currentActivityBBox animated:YES];
//        return;
    }

    
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

- (void)dismissPopover {
    [_popover dismiss:YES];
}

#pragma Actions

- (IBAction)startAction:(id)sender {
    _record = YES;
    _activity = [EAIActivity activity];
    
    //_locations = [@[] mutableCopy];
//    [_locationManager startUpdatingLocation];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView showsUserLocation];
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
}

- (IBAction)stopAction:(id)sender {
//    [_locationManager disallowDeferredLocationUpdates];
    //[_locationManager stopUpdatingLocation];
    _record = NO;
}

- (IBAction)toggleMapAndGraph:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl*)sender;
    if (seg.selectedSegmentIndex == 0) {
        self.mapView.hidden = NO;
        // map visible
        _profileView.hidden = YES;
        // graph hidden
        _speedView.hidden = YES;
        // speed hidden
    }
    else if (seg.selectedSegmentIndex == 1) {
        self.mapView.hidden = YES;
        // map hidden
        _profileView.hidden = NO;
        // graph visible
        _speedView.hidden = YES;
    }
    else {
        self.mapView.hidden = YES;
        // map hidden
        _profileView.hidden = YES;
        // graph visible
        _speedView.hidden = NO;
    }
}

- (IBAction)showActivities:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dirPath = paths[0];
    NSArray *filepaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    _activityFiles = [@[] mutableCopy];
    for (NSString *path in filepaths) {
        if ([path hasSuffix:@".json"]) {
            [_activityFiles addObject:path];
        }
    }

    _activityListVC = [[EAIActivityListViewController alloc] init];
    __weak EAIViewController *weakSelf = self;
    __weak EAIActivityListViewController *weakActivityVC = _activityListVC;
    _activityListVC.activitySelectBlock = ^(NSURL *fileURL) {
        [weakSelf loadDataForActivityAtURL:fileURL];
        //[weakSelf performSelectorOnMainThread:@selector(dismissPopover) withObject:nil waitUntilDone:NO];
        [weakActivityVC dismissViewControllerAnimated:YES completion:NULL];
    };
    [self presentViewController:_activityListVC animated:YES completion:NULL];
//    CGRect r = [(UIButton*)sender frame];
//    [PopoverView showPopoverAtPoint:CGPointMake(r.origin.x + r.size.width/2, r.origin.y) inView:self.view withStringArray:_activityFiles delegate:self];
//    CGPoint center = CGPointMake(r.origin.x + r.size.width/2, r.origin.y);
//    [PopoverView showPopoverAtPoint:center
//                             inView:self.view
//                          withTitle:@"Activities"
//                    withContentView:_activityListVC.view
//                           delegate:self];
//    [PopoverView showPopoverAtPoint:CGPointMake(r.origin.x + r.size.width/2, r.origin.y) inView:self.view withContentView:_activityListVC.view delegate:self];
}

-(void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"called");
    [popoverView dismiss:YES];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dirPath = paths[0];
    NSString *path = [NSString stringWithFormat:@"%@/%@",dirPath, _activityFiles[index]];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    [self loadDataForActivityAtURL:fileURL];
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
            //NSLog(@"elevations: %@", elevations);
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
                                         options:0
                                           error:&error];
            [outStream close];
            if (error) {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error Serializing JSON"
                                                             message:[error localizedDescription]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles: nil];
//                [av show];
                [weakSelf showAlertOnMainThread:av];
                NSLog(@"error serializing JSON: %@", error);
            }
            else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Activity Saved!"
                                                             message:[NSString stringWithFormat:@"%d.json", (int)nowSecs]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles: nil];
//                [av show];
                [weakSelf showAlertOnMainThread:av];
            }
        }
        else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error getting elevations"
                                                         message:[error localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles: nil];
            //[av show];
            [weakSelf showAlertOnMainThread:av];
            NSLog(@"error getting elevations: %@", error);
        }
    };
//    [_elevationTask findGoogleElevationsForLocations:_activity.locations];
//    [_elevationTask findAstergdemElevationsForLocations:_activity.locations];
    [_elevationTask calculateElevationsForLocations:_activity.locations];
}

- (void)showAlertOnMainThread:(UIAlertView*)av {
    [av performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
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

#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay
{
    //if we have not yet created an overlay view for this overlay, create it now.
//    if(!_currentActivityView)
//    {
        _currentActivityView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        _currentActivityView.fillColor = [UIColor blueColor];
        _currentActivityView.strokeColor = [UIColor blueColor];
        _currentActivityView.lineWidth = 5;
//    }

    return _currentActivityView;
    
}
@end
