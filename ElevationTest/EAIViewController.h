//
//  EAIViewController.h
//  ElevationTest
//
//  Created by Eric Ito on 8/3/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface EAIViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)exportLocations:(id)sender;
- (IBAction)startAction:(id)sender;
- (IBAction)stopAction:(id)sender;
- (IBAction)toggleMapAndGraph:(id)sender;

- (IBAction)showActivities:(id)sender;
@end
