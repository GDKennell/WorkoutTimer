//
//  WorkoutSection.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "WorkoutSection.h"

#import <AVFoundation/AVAudioPlayer.h>

@implementation WorkoutSound

+ (WorkoutSound *)soundWithFileName:(NSString *)soundName {
    WorkoutSound *newSound = [[WorkoutSound alloc] init];
    NSString *soundPath = [[NSBundle mainBundle]
                            pathForResource:soundName ofType:@"caf"];
    NSAssert(soundPath != nil, @"Could not get path for sound name %@", soundName);
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    SystemSoundID soundId;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
    newSound.soundId = soundId;
    
    NSError *error = nil;
    AVAudioPlayer* avAudioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:soundURL error:&error];
    NSAssert(avAudioPlayer && !error, @"Failure : %@", error);
    
    newSound.duration = avAudioPlayer.duration;

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
    newSection.timeRemaining = duration;
    newSection.name = name;
    return newSection;
}

@end
