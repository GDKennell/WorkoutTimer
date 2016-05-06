//
//  DataStore.h
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WorkoutSection.h"

@interface DataStore : NSObject

@property (readonly) NSMutableArray *workoutSections;

@property NSTimeInterval totalWorkoutTime;

+ (DataStore *)sharedDataStore;

- (void)addWorkoutSection:(WorkoutSection *)section;

@end
