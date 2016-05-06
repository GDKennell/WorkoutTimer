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

@import AudioToolbox;

#define NORMAL_CELL_BACKGROUND_COLOR [UIColor colorWithRed:0.931821f green:0.931821f blue:0.931821f alpha:1.0f]
#define HIGHLIGHTED_CELL_BACKGROUND_COLOR [UIColor colorWithRed:1.0f green:0.833506 blue:0.23678 alpha:1.0f]

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
@property NSTimer *countDownTimer;

@end

@implementation SectionListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Play silence first because of delay in first sound
    WorkoutSound *silence = [WorkoutSound soundWithFileName:@"silence"];
    [silence playThenCallSelector:nil onTarget:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.currentSection = -1;
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
    cell.timeLabel.text = [NSString stringWithTimeInterval:workoutSection.timeRemaining];
    cell.mainLabel.text = workoutSection.name;
    
    if (self.currentSection == indexPath.row) {
        cell.backgroundColor = HIGHLIGHTED_CELL_BACKGROUND_COLOR;
    }
    else {
        cell.backgroundColor = NORMAL_CELL_BACKGROUND_COLOR;
    }
    
    return cell;
}

- (IBAction)startWorkoutButtonPressed:(id)sender {
    self.currentSection = -1; // playBeforeSound will do the increment
    [self playBeforeSound];
}

- (void)playBeforeSound {
    NSLog(@"Before sound %d", self.currentSection);
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    if (self.currentSection >= (NSInteger)workoutSections.count) {
        [self workoutComplete];
        return;
    }
    
    WorkoutSection *nextSection = workoutSections[self.currentSection + 1];
    if (nextSection.beforeSound) {
        NSLog(@"Playing before sound for duration %f", nextSection.beforeSound.duration);
        [nextSection.beforeSound playThenCallSelector:@selector(startSection) onTarget:self];
    }
    else {
        [self startSection];
    }
}

- (void)playStartSound {
    NSLog(@"Start sound %d", self.currentSection);

    if (self.currentSection == 0) {
        [self startMainTimer];
    }
    
    WorkoutSection *currentSection = [[DataStore sharedDataStore] workoutSections][self.currentSection];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

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

- (void)startSection {
    ++self.currentSection;
    [self playStartSound];
    // Stop the timer in sectionIndex - 1 if sectionIndex > 0
    // Change main bottom label to indicate current section
}

- (void)startMainTimer {
    self.countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(decrementTime) userInfo:nil repeats:YES];
}

- (void)decrementTime {
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    WorkoutSection *currentSection = workoutSections[self.currentSection];
    currentSection.timeRemaining -= 1.0f;
    [self.tableView reloadData];
}

- (void)workoutComplete {
    WorkoutSound *workoutCompleteSound = [WorkoutSound soundWithFileName:WORKOUT_COMPLETE_FILENAME];
    [workoutCompleteSound playThenCallSelector:nil onTarget:nil];
}

@end
