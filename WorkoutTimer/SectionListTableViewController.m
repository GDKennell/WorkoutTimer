//
//  SectionListTableViewController.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "SectionListTableViewController.h"
#import "SectionListTableViewCell.h"
#import "DataStore.h"
#import "WorkoutViewController.h"
#import "NSString+Utils.h"

#define START_WORKOUT_FILENAME @"start_workout"
#define START_WARMUP_WORKOUT_FILENAME @"begin_warmup"
#define BEFORE_INTENSE_FILENAME @"before_intense"
#define START_INTENSE_FILENAME @"start_intense"
#define BEFORE_SLOW_FILENAME @"before_slow"
#define START_SLOW_FILENAME @"start_slow"
#define BEFORE_COOLDOWN_FILENAME @"before_cooldown"
#define START_COOLDOWN_FILENAME @"start_cooldown"
#define WORKOUT_COMPLETE_FILENAME @"workout_complete"

@interface SectionListTableViewController ()

@property IBOutlet UITableView *tableView;
@property NSInteger currentSection;

@end

@implementation SectionListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    WorkoutSection *warmupSection = [WorkoutSection sectionWithDuration:180.0f name:@"Warmup"];
    warmupSection.beforeSound = [WorkoutSound soundWithFileName:START_WORKOUT_FILENAME];
    warmupSection.startSound = [WorkoutSound soundWithFileName:START_WARMUP_WORKOUT_FILENAME];
    
    WorkoutSection *intenseSection = [WorkoutSection sectionWithDuration:20.0f name:@"Intense"];
    intenseSection.beforeSound = [WorkoutSound soundWithFileName:BEFORE_INTENSE_FILENAME];
    intenseSection.startSound = [WorkoutSound soundWithFileName:START_INTENSE_FILENAME];

    WorkoutSection *slowSection = [WorkoutSection sectionWithDuration:120.0f name:@"Slow"];
    slowSection.beforeSound = [WorkoutSound soundWithFileName:BEFORE_SLOW_FILENAME];
    slowSection.startSound = [WorkoutSound soundWithFileName:START_SLOW_FILENAME];
    
    WorkoutSection *cooldownSection = [WorkoutSection sectionWithDuration:120.0f name:@"Cooldown"];
    cooldownSection.beforeSound = [WorkoutSound soundWithFileName:BEFORE_COOLDOWN_FILENAME];
    cooldownSection.startSound = [WorkoutSound soundWithFileName:START_COOLDOWN_FILENAME];

    DataStore *dataStore = [DataStore sharedDataStore];

    [dataStore addWorkoutSection:warmupSection];
    [dataStore addWorkoutSection:intenseSection];
    [dataStore addWorkoutSection:slowSection];
    [dataStore addWorkoutSection:intenseSection];
    [dataStore addWorkoutSection:slowSection];
    [dataStore addWorkoutSection:intenseSection];
    [dataStore addWorkoutSection:cooldownSection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[DataStore sharedDataStore] workoutSections] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SectionListTableViewCell *cell = (SectionListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SectionListTableViewCell" forIndexPath:indexPath];

    WorkoutSection *workoutSection = [[[DataStore sharedDataStore] workoutSections] objectAtIndex:indexPath.row];
    cell.timeLabel.text = [NSString stringWithTimeInterval:workoutSection.duration];
    cell.mainLabel.text = workoutSection.name;
    
    return cell;
}

- (IBAction)startWorkoutButtonPressed:(id)sender {
    self.currentSection = -1; // playBeforeSound will do the increment
    [self playBeforeSound];
}

- (void)playBeforeSound {
    ++self.currentSection;
    NSLog(@"Before sound %d", self.currentSection);
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    if (self.currentSection >= workoutSections.count) {
        [self workoutComplete];
        return;
    }
    
    WorkoutSection *currentSection = workoutSections[self.currentSection];
    if (currentSection.beforeSound) {
        NSLog(@"Playing before sound for duration %f", currentSection.beforeSound.duration);
        [currentSection.beforeSound playThenCallSelector:@selector(playStartSound) onTarget:self];
    }
    else {
        [self playStartSound];
    }
}

- (void)playStartSound {
    NSLog(@"Start sound %d", self.currentSection);

    if (self.currentSection == 0) {
        [self startMainTimer];
    }
    [self startSection:self.currentSection];
    
    WorkoutSection *currentSection = [[DataStore sharedDataStore] workoutSections][self.currentSection];
    if (currentSection.startSound) {
        NSLog(@"Playing start sound for duration %f", currentSection.startSound.duration);
        [currentSection.startSound playThenCallSelector:@selector(runSection) onTarget:self];
    }
    else {
        [self runSection];
    }
}

- (void)runSection {
    NSLog(@"Run Section %d", self.currentSection);

    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    WorkoutSection *currentSection = workoutSections[self.currentSection];
    NSTimeInterval runDuration = currentSection.duration;
    if (currentSection.startSound) {
        runDuration -= currentSection.startSound.duration;
    }
    if (self.currentSection + 1 < workoutSections.count && workoutSections[self.currentSection + 1].beforeSound) {
        runDuration -= workoutSections[self.currentSection + 1].beforeSound.duration;
    }
    
    NSLog(@"Running for duration %f", runDuration);

    NSTimer *tempTimer = [NSTimer scheduledTimerWithTimeInterval:runDuration target:self selector:@selector(playBeforeSound) userInfo:nil repeats:NO];
}

- (void)startSection:(NSInteger)sectionIndex {
    // Start the timer in sectionIndex
    // Stop the timer in sectionIndex - 1 if sectionIndex > 0
    // Change main bottom label to indicate current section
}

- (void)startMainTimer {
    // Start the main bottom timer
}

- (void)workoutComplete {
    WorkoutSound *workoutCompleteSound = [WorkoutSound soundWithFileName:WORKOUT_COMPLETE_FILENAME];
    [workoutCompleteSound playThenCallSelector:nil onTarget:nil];
}

@end
