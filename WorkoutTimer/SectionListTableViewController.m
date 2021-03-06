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

#import "AboutViewController.h"

#import "AnalyticsConstants.h"

@import AudioToolbox;
@import Firebase;

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


@property (getter=isWorkoutPaused)     BOOL workoutPaused;
@property (getter=isWorkoutInProgress) BOOL workoutInProgress;

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

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    BOOL hasBeenLaunchedBefore = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasBeenLaunchedBefore"];
    if (!hasBeenLaunchedBefore) {
        [self displayAboutPage];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasBeenLaunchedBefore"];
        self.workoutPaused = NO;
        self.workoutInProgress = NO;
    }

    [self appWillEnterForeground];
}

- (void)appDidEnterBackground {
    [[NSUserDefaults standardUserDefaults] setObject:@(self.totalTimeLeft) forKey:kTotalTimeLeftKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kAppBackgroundedDate];
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
    if (self.isWorkoutPaused) {
        [self.playPauseButton setEnabled:YES];
        [self.playPauseButton setTitle:@"Resume" forState:UIControlStateNormal];

        self.totalTimeLeft = previousTotalTimeLeft;
        [self restoreCurrentSection];
        [self updateBottomBar];
        [self.resetButton setEnabled:YES];
    }
    else if (self.isWorkoutInProgress) {
        NSDate *backgroundedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kAppBackgroundedDate];
        NSTimeInterval timeInBackground = [[NSDate date] timeIntervalSinceDate:backgroundedDate];

        NSTimeInterval totalTimeLeft =  previousTotalTimeLeft - timeInBackground;
        if (totalTimeLeft > 0) {
            self.totalTimeLeft = totalTimeLeft;
            [self restoreCurrentSection];
            [self resumeWorkout];
            [self.resetButton setEnabled:YES];
        }
        else {
            NSLog(kWorkoutCompletedAnalyticsKey);
            [FIRAnalytics logEventWithName:kWorkoutCompletedAnalyticsKey parameters:nil];
            [self workoutCompleteAndPlaySound:NO];
        }
    }
    else {
        [self resetBottomBar];
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
        cell.timeLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        cell.mainLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    }
    else {
        cell.backgroundColor = NORMAL_CELL_BACKGROUND_COLOR;
        cell.timeLabel.font = [UIFont systemFontOfSize:17.0f];
        cell.mainLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (IBAction)playPauseButtonPressed {
    [FIRAnalytics logEventWithName:kWorkoutPausedOrResumedAnalyticsKey parameters:nil];

    if (!self.isWorkoutPaused) {
        self.workoutPaused = YES;

        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        [self.playPauseButton setTitle:@"Resume" forState:UIControlStateNormal];
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
        [self.currentTimer invalidate];
        self.currentTimer = nil;
    }
    else {
        self.workoutPaused = NO;
        [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        [self resumeWorkout];
    }
}

- (IBAction)aboutButtonPressed:(id)sender {
    [FIRAnalytics logEventWithName:kAboutButtonPressedAnalyticsKey parameters:nil];
    [self displayAboutPage];
}

- (void)displayAboutPage {
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController *aboutVC = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AboutVC"];
    [self presentViewController:aboutVC animated:YES completion:nil];
}

- (IBAction)resetButtonPressed {
    [FIRAnalytics logEventWithName:kWorkoutResetAnalyticsKey parameters:nil];
    self.workoutPaused = NO;
    [self workoutCompleteAndPlaySound:NO];
}

- (IBAction)startWorkoutButtonPressed:(id)sender {
    self.startWorkoutButton.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.3];
}

- (IBAction)startWorkButtonReleased:(id)sender {
    self.startWorkoutButton.backgroundColor = [UIColor clearColor];
    [FIRAnalytics logEventWithName:kWorkoutStartedAnalyticsKey parameters:nil];

    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    self.currentSection = -1; // playBeforeSound will do the increment
    self.workoutInProgress = YES;
    self.workoutPaused = NO;
    [self playBeforeSound];
    [self.startWorkoutButton setEnabled:NO];
}

- (void)playBeforeSound {
    NSLog(@"Before sound %d", self.currentSection);
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    if (self.currentSection + 1 >= (NSInteger)workoutSections.count) {
        [FIRAnalytics logEventWithName:kWorkoutCompletedAnalyticsKey parameters:nil];
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
        if (sectionIndex == self.currentSection + 1 && section.beforeSound && section.beforeSound.duration < timeRemainingInCurentSection) {
            timeRemainingInCurentSection -= section.beforeSound.duration;
            fireDate = [NSDate dateWithTimeIntervalSinceNow:timeRemainingInCurentSection];
        }
        if (section.beforeSound) {
            [self scheduleLocalNotificationWithFireDate:fireDate alertBody:nil soundName:section.beforeSound.fileName];
            fireDate = [fireDate initWithTimeInterval:section.beforeSound.duration sinceDate:fireDate];
        }
        [self scheduleLocalNotificationWithFireDate:fireDate alertBody:[NSString stringWithFormat:@"Start %@ section", section.name] soundName:section.startSound.fileName];

        timeRemainingInCurentSection = section.duration;
        if (sectionIndex + 1 < [[[DataStore sharedDataStore] workoutSections] count]) {
            WorkoutSection *nextSection = [[[DataStore sharedDataStore] workoutSections] objectAtIndex:sectionIndex + 1];
            if (nextSection.beforeSound) {
                timeRemainingInCurentSection -= nextSection.beforeSound.duration;
            }
        }

        fireDate = [NSDate dateWithTimeInterval:timeRemainingInCurentSection sinceDate:fireDate];
    }
    [self scheduleLocalNotificationWithFireDate:fireDate alertBody:@"Workout Complete" soundName:[NSString stringWithFormat:@"%@.caf",WORKOUT_COMPLETE_FILENAME]];
}

- (void)scheduleLocalNotificationWithFireDate:(NSDate *)fireDate alertBody:(NSString *)alertBody soundName:(NSString *)filename {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = fireDate;
    notification.soundName = filename;
    notification.alertBody = alertBody;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
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
    [FIRAnalytics logEventWithName:kWorkoutCompletedAnalyticsKey parameters:nil];
    [self workoutCompleteAndPlaySound:YES];
}

- (void)workoutCompleteAndPlaySound:(BOOL)playSound {
    self.workoutInProgress = NO;
    self.workoutPaused = NO;

    if (playSound) {
        WorkoutSound *workoutCompleteSound = [WorkoutSound soundWithFileName:WORKOUT_COMPLETE_FILENAME];
        [workoutCompleteSound playThenCallSelector:nil onTarget:nil];
    }
    [self.countDownTimer invalidate];
    self.countDownTimer = nil;

    [self.currentTimer invalidate];
    self.currentTimer = nil;

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

- (void)setWorkoutInProgress:(BOOL)workoutInProgress {
    [[NSUserDefaults standardUserDefaults] setBool:workoutInProgress forKey:kWorkoutInProgressKey];
}

- (BOOL)isWorkoutInProgress {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kWorkoutInProgressKey];
}

- (void)setWorkoutPaused:(BOOL)workoutPaused {
    [[NSUserDefaults standardUserDefaults] setBool:workoutPaused forKey:kWorkoutPausedKey];
}

- (BOOL)isWorkoutPaused {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kWorkoutPausedKey];
}

@end
