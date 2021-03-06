//
//  WorkoutSection.h
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AudioToolbox;

@interface WorkoutSound : NSObject <NSCoding>

@property SystemSoundID soundId;
@property NSString *fileName;
@property NSTimeInterval duration;

+ (WorkoutSound *)soundWithFileName:(NSString *)soundName;

- (NSTimer *)playThenCallSelector:(SEL)sel onTarget:(id)target;

@end

@interface WorkoutSection : NSObject <NSCopying, NSCoding>

@property NSTimeInterval duration;
@property NSString *name;

@property WorkoutSound *beforeSound;
@property WorkoutSound *startSound;

// Calculated property when added to DataStore
@property NSTimeInterval startTime;
@property NSTimeInterval timeRemaining;


//@property

+ (WorkoutSection *)sectionWithDuration:(NSTimeInterval)duration name:(NSString *)name;

@end
