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

#define BOTTOM_BAR_BUTTON_COLOR [UIColor colorWithRed:0.118455f green:1 blue:0.52467 alpha:1.0f]
#define BOTTOM_BAR_DISPLAY_COLOR HIGHLIGHTED_CELL_BACKGROUND_COLOR

#define START_WORKOUT_FILENAME @"start_workout"
#define START_WARMUP_WORKOUT_FILENAME @"begin_warmup"
#define BEFORE_INTENSE_FILENAME @"before_intense"
#define START_INTENSE_FILENAME @"start_intense"
#define BEFORE_SLOW_FILENAME @"before_slow"
#define START_SLOW_FILENAME @"start_slow"
#define BEFORE_COOLDOWN_FILENAME @"before_cooldown"
#define START_COOLDOWN_FILENAME @"start_cooldown"
#define WORKOUT_COMPLETE_FILENAME @"workout_complete"

#define kTotalTimeLeftKey @"TotalTimeLeft"
#define kAppBackgroundedDate @"AppBackgroundedDate"
#define kWorkoutPausedKey @"WorkoutPaused"
#define kWorkoutInProgressKey @"WorkoutInProgress"

@interface SectionListTableViewController ()

@property IBOutlet UITableView *tableView;
@property NSInteger currentSection;

@property NSTimer *countDownTimer;
@property NSTimer *currentTimer;

// Bottom section
@property IBOutlet UIView *bottomBarContainer;
@property IBOutlet UILabel *totalTimeLabel;
@property IBOutlet UILabel *bottomMiddleLabel;
@property IBOutlet UILabel *sectionNumberLabel;
@property IBOutlet UIButton *startWorkoutButton;

@property IBOutlet UIButton *resetButton;
@property IBOutlet UIButton *playPauseButton;

@property NSTimeInterval totalTimeLeft;


@property BOOL isWorkoutPaused;
@property (readonly) BOOL isWorkoutInProgress;

@end

@implementation SectionListTableViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Play silence first because of delay in first sound
    WorkoutSound *silence = [WorkoutSound soundWithFileName:@"silence"];
    [silence playThenCallSelector:nil onTarget:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.currentSection = -1;
    
    [self.resetButton setEnabled:NO];
    [self.playPauseButton setEnabled:NO];

    self.navigationItem.title = @"10:1 Interval";
    
    WorkoutSection *warmupSection = [WorkoutSection sectionWithDuration:180.0f name:@"Warmup"];
    warmupSection.beforeSound = [WorkoutSound soundWithFileName:START_WORKOUT_FILENAME];
    warmupSection.startSound = [WorkoutSound soundWithFileName:START_WARMUP_WORKOUT_FILENAME];
    
    WorkoutSection *intenseSection = [WorkoutSection sectionWithDuration: 20.0f name:@"Intense"];
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
    [dataStore addWorkoutSection:[intenseSection copy]];
    [dataStore addWorkoutSection:[slowSection copy]];
    [dataStore addWorkoutSection:[intenseSection copy]];
    [dataStore addWorkoutSection:cooldownSection];
    
    self.totalTimeLeft = dataStore.totalWorkoutTime;
    
    self.isWorkoutPaused = NO;

    [self appWillEnterForeground];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)appDidEnterBackground {
    [[NSUserDefaults standardUserDefaults] setObject:@(self.totalTimeLeft) forKey:kTotalTimeLeftKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kAppBackgroundedDate];
    [[NSUserDefaults standardUserDefaults] setBool:self.isWorkoutPaused forKey:kWorkoutPausedKey];
    [[NSUserDefaults standardUserDefaults] setBool:self.isWorkoutInProgress forKey:kWorkoutInProgressKey];
    [self.countDownTimer invalidate];
    self.countDownTimer = nil;
    [self.currentTimer invalidate];
    self.currentTimer = nil;
}

- (void)restoreCurrentSection {
    NSTimeInterval totalElapsedTime = [[DataStore sharedDataStore] totalWorkoutTime] - self.totalTimeLeft;
    
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    NSTimeInterval tempTime = 0.0f;
    self.currentSection = -1;
    for (WorkoutSection *section in workoutSections) {
        ++self.currentSection;
        section.startTime = tempTime;
        tempTime += section.duration;
        if (totalElapsedTime < tempTime) {
            NSTimeInterval sectionTimeElapsed = totalElapsedTime - section.startTime;
            section.timeRemaining = section.duration - sectionTimeElapsed;
            break;
        }
        else {
            section.timeRemaining = 0.0f;
        }
    }
}

- (void)resumeWorkout {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [self startMainTimer];
    
    WorkoutSection *currentSection = [[[DataStore sharedDataStore] workoutSections] objectAtIndex:self.currentSection];
    
    NSTimeInterval totalElapsedTime = [[DataStore sharedDataStore] totalWorkoutTime] - self.totalTimeLeft;
    NSTimeInterval timeElapsedInCurrentSection = totalElapsedTime - currentSection.startTime;
    NSTimeInterval timeRemainingInCurentSection = currentSection.duration - timeElapsedInCurrentSection;
    
    // If in last section
    if (self.currentSection == [[[DataStore sharedDataStore] workoutSections] count] - 1) {
        self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:timeRemainingInCurentSection target:self selector:@selector(workoutComplete) userInfo:nil repeats:NO];
    }
    else {
        WorkoutSection *nextSection =[[[DataStore sharedDataStore] workoutSections] objectAtIndex:self.currentSection + 1];
        NSTimeInterval timeUntilNextBeforeSound = timeRemainingInCurentSection - nextSection.beforeSound.duration;
        if (timeUntilNextBeforeSound > 0) {
            self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:timeUntilNextBeforeSound target:self selector:@selector(playBeforeSound) userInfo:nil repeats:NO];
        }
        else {
            self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:timeRemainingInCurentSection target:self selector:@selector(playStartSoundAndIncrementCurrentSection) userInfo:nil repeats:NO];
        }
    }
}

- (void)appWillEnterForeground {
    NSTimeInterval previousTotalTimeLeft = [[[NSUserDefaults standardUserDefaults] objectForKey:kTotalTimeLeftKey] doubleValue];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kWorkoutPausedKey]) {
        self.isWorkoutPaused = YES;
        [self.playPauseButton setEnabled:YES];
        [self.playPauseButton setTitle:@"Resume" forState:UIControlStateNormal];

        self.totalTimeLeft = previousTotalTimeLeft;
        [self restoreCurrentSection];
        [self updateBottomBar];
        [self.resetButton setEnabled:YES];
    }
    else {
        NSDate *backgroundedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kAppBackgroundedDate];
        NSTimeInterval timeInBackground = [[NSDate date] timeIntervalSinceDate:backgroundedDate];

        NSTimeInterval totalTimeLeft =  previousTotalTimeLeft - timeInBackground;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kWorkoutInProgressKey] && totalTimeLeft > 0) {
            self.totalTimeLeft = totalTimeLeft;
            [self restoreCurrentSection];
            [self resumeWorkout];
            [self.resetButton setEnabled:YES];
        }
        else {
            [self workoutCompleteAndPlaySound:NO];
        }
    }
}

- (void)resetBottomBar {
    [self.totalTimeLabel setHidden:YES];
    [self.sectionNumberLabel setHidden:YES];
    self.bottomMiddleLabel.text = @"Start Workout";
    [self.startWorkoutButton setEnabled:YES];
    self.totalTimeLeft = [[DataStore sharedDataStore] totalWorkoutTime];
    self.bottomBarContainer.backgroundColor = BOTTOM_BAR_BUTTON_COLOR;
}

- (void)updateBottomBar {
    NSTimeInterval elapsedTime = [[DataStore sharedDataStore] totalWorkoutTime] - self.totalTimeLeft;
    self.totalTimeLabel.text = [NSString stringWithTimeInterval:elapsedTime];
    [self.totalTimeLabel setHidden:NO];
    
    self.sectionNumberLabel.text = [NSString stringWithFormat:@"%ld / %ld", (long)self.currentSection + 1, (long)[[[DataStore sharedDataStore] workoutSections] count]];
    [self.sectionNumberLabel setHidden:NO];

    self.bottomMiddleLabel.text = [[[[DataStore sharedDataStore] workoutSections] objectAtIndex:self.currentSection] name];
    self.bottomBarContainer.backgroundColor = BOTTOM_BAR_DISPLAY_COLOR;
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
        self.bottomMiddleLabel.text = workoutSection.name;
    }
    else {
        cell.backgroundColor = NORMAL_CELL_BACKGROUND_COLOR;
    }
    
    return cell;
}

- (IBAction)playPauseButtonPressed {
    if (self.isWorkoutInProgress) {
        self.isWorkoutPaused = YES;
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        [self.playPauseButton setTitle:@"Resume" forState:UIControlStateNormal];
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
        [self.currentTimer invalidate];
        self.currentTimer = nil;
    }
    else {
        self.isWorkoutPaused = NO;
        [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        [self resumeWorkout];
    }
}

- (IBAction)resetButtonPressed {
    self.isWorkoutPaused = NO;
    [self workoutCompleteAndPlaySound:NO];
}

- (IBAction)startWorkoutButtonPressed:(id)sender {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    self.currentSection = -1; // playBeforeSound will do the increment
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWorkoutInProgressKey];
    [self playBeforeSound];
    [self.startWorkoutButton setEnabled:NO];
}

- (void)playBeforeSound {
    NSLog(@"Before sound %d", self.currentSection);
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    if (self.currentSection + 1 >= (NSInteger)workoutSections.count) {
        [self workoutCompleteAndPlaySound:YES];
        return;
    }
    
    WorkoutSection *nextSection = workoutSections[self.currentSection + 1];
    if (nextSection.beforeSound) {
        NSLog(@"Playing before sound for duration %f", nextSection.beforeSound.duration);
        self.currentTimer = [nextSection.beforeSound playThenCallSelector:@selector(startSection) onTarget:self];
    }
    else {
        [self startSection];
    }
}

- (void)playStartSoundAndIncrementCurrentSection {
    ++self.currentSection;
    [self playStartSound];
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
        self.currentTimer = [currentSection.startSound playThenCallSelector:@selector(runSection) onTarget:self];
    }
    else {
        [self runSection];
    }
}

- (void)runSection {
    NSLog(@"Run Section %ld", (long)self.currentSection);

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

    self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:runDuration target:self selector:@selector(playBeforeSound) userInfo:nil repeats:NO];
}

- (void)startSection {
    ++self.currentSection;
    [self updateBottomBar];

    [self playStartSound];
    [self.tableView reloadData];
    // Stop the timer in sectionIndex - 1 if sectionIndex > 0
    // Change main bottom label to indicate current section
}

- (void)startMainTimer {
    [self updateBottomBar];
    [self scheduleLocalNotifications];
    self.countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(decrementTime) userInfo:nil repeats:YES];
    [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [self.playPauseButton setEnabled:YES];
    [self.resetButton setEnabled:YES];
}

- (void)scheduleLocalNotifications {
    WorkoutSection *currentSection = [[[DataStore sharedDataStore] workoutSections] objectAtIndex:self.currentSection];
    NSTimeInterval totalElapsedTime = [[DataStore sharedDataStore] totalWorkoutTime] - self.totalTimeLeft;
    NSTimeInterval timeElapsedInCurrentSection = totalElapsedTime - currentSection.startTime;
    NSTimeInterval timeRemainingInCurentSection = currentSection.duration - timeElapsedInCurrentSection;

    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:timeRemainingInCurentSection];
    for (NSInteger sectionIndex = self.currentSection + 1; sectionIndex < [[[DataStore sharedDataStore] workoutSections] count]; ++sectionIndex) {
        WorkoutSection *section = [[[DataStore sharedDataStore] workoutSections] objectAtIndex:sectionIndex];
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = fireDate;
        notification.soundName = section.startSound.fileName;
        notification.alertBody = [NSString stringWithFormat:@"Start %@ section", section.name];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        fireDate = [NSDate dateWithTimeInterval:section.duration sinceDate:fireDate];
    }
    UILocalNotification *workoutCompleteNotification = [[UILocalNotification alloc] init];
    workoutCompleteNotification.fireDate = fireDate;
    workoutCompleteNotification.soundName = [NSString stringWithFormat:@"%@.caf", WORKOUT_COMPLETE_FILENAME];
    workoutCompleteNotification.alertBody = @"Workout Complete";
    [[UIApplication sharedApplication] scheduleLocalNotification:workoutCompleteNotification];
}

- (void)decrementTime {
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    WorkoutSection *currentSection = workoutSections[self.currentSection];
    currentSection.timeRemaining -= 1.0f;
    self.totalTimeLeft -= 1.0f;
    NSTimeInterval elapsedTime = [[DataStore sharedDataStore] totalWorkoutTime] - self.totalTimeLeft;
    self.totalTimeLabel.text = [NSString stringWithTimeInterval:elapsedTime];
    [self.tableView reloadData];
}

- (void)workoutComplete {
    [self workoutCompleteAndPlaySound:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWorkoutInProgressKey];
}

- (void)workoutCompleteAndPlaySound:(BOOL)playSound {
    if (playSound) {
        WorkoutSound *workoutCompleteSound = [WorkoutSound soundWithFileName:WORKOUT_COMPLETE_FILENAME];
        [workoutCompleteSound playThenCallSelector:nil onTarget:nil];
    }
    [self.countDownTimer invalidate];
    self.countDownTimer = nil;
    self.currentSection = -1;
    for (WorkoutSection *section in [[DataStore sharedDataStore] workoutSections]) {
        section.timeRemaining = section.duration;
    }
    [self.tableView reloadData];
    [self resetBottomBar];
    [self.playPauseButton setEnabled:NO];
    [self.resetButton setEnabled:NO];

    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (BOOL)isWorkoutInProgress {
    return self.countDownTimer != nil;
}

- (BOOL)isIsWorkoutPaused {
    return !self.isWorkoutInProgress && self.totalTimeLeft < [[DataStore sharedDataStore] totalWorkoutTime];
}

@end
