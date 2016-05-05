//
//  WorkoutSection.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "WorkoutSection.h"

@implementation WorkoutSection

+ (WorkoutSection *)sectionWithDuration:(NSTimeInterval)duration name:(NSString *)name {
    WorkoutSection *newSection = [[WorkoutSection alloc] init];
    newSection.duration = duration;
    newSection.name = name;
    return newSection;
}

@end
