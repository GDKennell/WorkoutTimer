//
//  WorkoutViewController.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "WorkoutViewController.h"
#import "DataStore.h"
#import "UIView+Utils.h"

#define MIN_SECTION_HEIGHT 16.0f

@interface WorkoutViewController ()

@property NSTimeInterval totalWorkoutTime;
@property NSArray *workoutSections;
@property CGFloat pixelsPerSecond;

@property UITableView *tableView;

@end

@implementation WorkoutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Size calculations
    self.totalWorkoutTime = 0.0f;
    self.workoutSections = [[[DataStore sharedDataStore] workoutSections] copy];
    for (WorkoutSection *section in self.workoutSections) {
        self.totalWorkoutTime += section.duration;
    }
    
    // Scaling to 10min for full view height
    self.pixelsPerSecond = self.view.frameHeight / 600.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
