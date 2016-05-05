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

@interface SectionListTableViewController ()

@property IBOutlet UITableView *tableView;

@end

@implementation SectionListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
     self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:180.0f name:@"Warmup"]];
    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:20.0f name:@"Intense"]];
    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:120.0f name:@"Slow"]];
    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:20.0f name:@"Intense"]];
    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:120.0f name:@"Slow"]];
    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:20.0f name:@"Intense"]];
    [[DataStore sharedDataStore] addWorkoutSection:[WorkoutSection sectionWithDuration:120.0f name:@"Cooldown"]];
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
    cell.timeLabel.text = [NSString stringWithFormat:@"%lf", workoutSection.duration];
    cell.mainLabel.text = workoutSection.name;
    
    return cell;
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
