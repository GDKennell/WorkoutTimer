//
//  WorkoutSection.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "WorkoutSection.h"

@implementation WorkoutSound

+ (WorkoutSound *)soundWithFileName:(NSString *)soundName duration:(NSTimeInterval)duration {
    WorkoutSound *newSound = [[WorkoutSound alloc] init];
    NSString *soundPath = [[NSBundle mainBundle]
                            pathForResource:soundName ofType:@"caf"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    SystemSoundID soundId;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
    newSound.soundId = soundId;
    newSound.duration = duration;
    return newSound;
}

- (void)playThenCallSelector:(SEL)sel onTarget:(id)target {
    AudioServicesPlaySystemSound(self.soundId);
    NSTimer *startTimer = [NSTimer scheduledTimerWithTimeInterval:self.duration target:target selector:sel userInfo:nil repeats:NO];
}

@end

@implementation WorkoutSection

+ (WorkoutSection *)sectionWithDuration:(NSTimeInterval)duration name:(NSString *)name {
    WorkoutSection *newSection = [[WorkoutSection alloc] init];
    newSection.duration = duration;
    newSection.name = name;
    return newSection;
}

@end
