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
#define START_WORKOUT_SOUND_DURATION 1.0f

#define START_WARMUP_WORKOUT_FILENAME @"warmup"
#define START_WARMUP_SOUND_DURATION 1.0f

#define BEFORE_INTENSE_FILENAME @"before_intense"
#define BEFORE_INTENSE_SOUND_DURATION 1.0f

#define START_INTENSE_FILENAME @"start_intense"
#define START_INTENSE_SOUND_DURATION 1.0f

#define BEFORE_SLOW_FILENAME @"before_slow"
#define BEFORE_SLOW_SOUND_DURATION 1.0f

#define START_SLOW_FILENAME @"start_slow"
#define START_SLOW_SOUND_DURATION 1.0f

#define BEFORE_COOLDOWN_FILENAME @"before_cooldown"
#define BEFORE_COOLDOWN_SOUND_DURATION 1.0f

#define START_COOLDOWN_FILENAME @"start_cooldown"
#define START_COOLDOWN_SOUND_DURATION 1.0f


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
    warmupSection.beforeSound = [WorkoutSound soundWithFileName:START_WORKOUT_FILENAME duration:START_WORKOUT_SOUND_DURATION];
    warmupSection.startSound = [WorkoutSound soundWithFileName:START_WARMUP_WORKOUT_FILENAME duration:START_WARMUP_SOUND_DURATION];
    
    WorkoutSection *intenseSection = [WorkoutSection sectionWithDuration:20.0f name:@"Intense"];
    intenseSection.beforeSound = [WorkoutSound soundWithFileName:BEFORE_INTENSE_FILENAME duration:BEFORE_INTENSE_SOUND_DURATION];
    intenseSection.startSound = [WorkoutSound soundWithFileName:START_INTENSE_FILENAME duration:START_INTENSE_SOUND_DURATION];

    WorkoutSection *slowSection = [WorkoutSection sectionWithDuration:120.0f name:@"Slow"];
    slowSection.beforeSound = [WorkoutSound soundWithFileName:BEFORE_SLOW_FILENAME duration:BEFORE_SLOW_SOUND_DURATION];
    slowSection.startSound = [WorkoutSound soundWithFileName:START_SLOW_FILENAME duration:START_SLOW_SOUND_DURATION];
    
    WorkoutSection *cooldownSection = [WorkoutSection sectionWithDuration:120.0f name:@"Cooldown"];
    cooldownSection.beforeSound = [WorkoutSound soundWithFileName:BEFORE_COOLDOWN_FILENAME duration:BEFORE_COOLDOWN_SOUND_DURATION];
    cooldownSection.startSound = [WorkoutSound soundWithFileName:START_COOLDOWN_FILENAME duration:START_COOLDOWN_SOUND_DURATION];

    DataStore *dataStore = [DataStore sharedDataStore];

    [dataStore addWorkoutSection:warmupSection];
    [dataStore addWorkoutSection:[intenseSection copy]];
    [dataStore addWorkoutSection:[slowSection copy]];
    [dataStore addWorkoutSection:[intenseSection copy]];
    [dataStore addWorkoutSection:[slowSection copy]];
    [dataStore addWorkoutSection:[intenseSection copy]];
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
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    if (self.currentSection >= workoutSections.count) {
        [self workoutComplete];
        return;
    }
    
    WorkoutSection *currentSection = workoutSections[self.currentSection];
    if (currentSection.beforeSound) {
        [currentSection.beforeSound playThenCallSelector:@selector(playStartSound) onTarget:self];
    }
    else {
        [self playStartSound];
    }
}

- (void)playStartSound {
    if (self.currentSection == 0) {
        [self startMainTimer];
    }
    [self startSection:self.currentSection];
    
    WorkoutSection *currentSection = [[DataStore sharedDataStore] workoutSections][self.currentSection];
    if (currentSection.startSound) {
        [currentSection.startSound playThenCallSelector:@selector(runSection) onTarget:self];
    }
    else {
        [self runSection];
    }
}

- (void)runSection {
    NSArray<WorkoutSection *> *workoutSections = [[DataStore sharedDataStore] workoutSections];
    WorkoutSection *currentSection = workoutSections[self.currentSection];
    NSTimeInterval runDuration = currentSection.duration;
    if (currentSection.startSound) {
        runDuration -= currentSection.startSound.duration;
    }
    if (self.currentSection + 1 < workoutSections.count && workoutSections[self.currentSection + 1].beforeSound) {
        runDuration -= workoutSections[self.currentSection + 1].beforeSound.duration;
    }
    
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
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
