//
//  EAIActivityListViewController.h
//  ElevationTest
//
//  Created by Eric Ito on 8/8/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAIActivityListViewController : UIViewController
@property (nonatomic, copy) void (^activitySelectBlock)(NSURL *fileURL);
@end
