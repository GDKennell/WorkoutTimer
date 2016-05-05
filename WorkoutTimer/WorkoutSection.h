//
//  WorkoutSection.h
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WorkoutSection : NSObject

@property NSTimeInterval duration;
@property NSString *name;
@property NSTimeInterval startTime;

+ (WorkoutSection *)sectionWithDuration:(NSTimeInterval)duration name:(NSString *)name;

@end
