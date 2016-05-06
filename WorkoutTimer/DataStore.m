//
//  DataStore.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "DataStore.h"

@interface DataStore ()

@property (readwrite) NSMutableArray<WorkoutSection *> *workoutSections;
@property NSTimeInterval totalWorkoutTime;

@end

@implementation DataStore

+ (DataStore *)sharedDataStore {
    static DataStore *theStore = nil;
    if (!theStore) {
        theStore = [[DataStore alloc] init];
        theStore.workoutSections = [NSMutableArray array];
        theStore.totalWorkoutTime = 0.0f;
    }
    
    return theStore;
}

- (void)addWorkoutSection:(WorkoutSection *)section {
    [self.workoutSections addObject:section];
    section.startTime = self.totalWorkoutTime;
    self.totalWorkoutTime += section.duration;
}

@end
