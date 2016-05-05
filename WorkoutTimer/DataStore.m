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

@end

@implementation DataStore

+ (DataStore *)sharedDataStore {
    static DataStore *theStore = nil;
    if (!theStore) {
        theStore = [[DataStore alloc] init];
        theStore.workoutSections = [NSMutableArray array];
    }
    
    return theStore;
}

- (void)addWorkoutSection:(WorkoutSection *)section {
    [self.workoutSections addObject:section];
}

@end
