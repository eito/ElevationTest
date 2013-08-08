//
//  EAIActivityListViewController.m
//  ElevationTest
//
//  Created by Eric Ito on 8/8/13.
//  Copyright (c) 2013 Eric Ito. All rights reserved.
//

#import "EAIActivityListViewController.h"

@interface EAIActivityListViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray *activityFilesPaths;
@end

@implementation EAIActivityListViewController

-(id)init {
    self = [super init];
    if (self) {
        self.activityFilesPaths = [@[] mutableCopy];
        self.view.bounds = CGRectMake(0, 0, 200, 200);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *dirPath = paths[0];
        NSArray *filepaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
        for (NSString *path in filepaths) {
            if ([path hasSuffix:@".json"]) {
                NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", dirPath, path]];
                [self.activityFilesPaths addObject:url];
            }
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UITableView *tv = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tv.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tv.delegate = self;
    tv.dataSource = self;
    [self.view addSubview:tv];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.activityFilesPaths.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellid = @"activitycellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellid];
    }
    NSString *name = [self.activityFilesPaths[indexPath.row] lastPathComponent];
    cell.textLabel.text = name;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = self.activityFilesPaths[indexPath.row];
    if (self.activitySelectBlock) {
        self.activitySelectBlock(url);
    }
}

@end
