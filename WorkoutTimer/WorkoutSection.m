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

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.soundId = [decoder decodeInt32ForKey:@"soundId"];
    self.fileName = [decoder decodeObjectForKey:@"fileName"];
    self.duration = [decoder decodeDoubleForKey:@"duration"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt32:self.soundId forKey:@"soundId"];
    [encoder encodeObject:self.fileName forKey:@"fileName"];
    [encoder encodeDouble:self.duration forKey:@"duration"];
}

#pragma mark -

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
    newSound.fileName = [NSString stringWithFormat:@"%@.caf", soundName];
    return newSound;
}

- (NSTimer *)playThenCallSelector:(SEL)sel onTarget:(id)target {
    AudioServicesPlaySystemSound(self.soundId);
    return [NSTimer scheduledTimerWithTimeInterval:self.duration target:target selector:sel userInfo:nil repeats:NO];    
}

@end


/*@property NSTimeInterval duration;
 @property NSString *name;
 
 @property WorkoutSound *beforeSound;
 @property WorkoutSound *startSound;
 
 // Calculated property when added to DataStore
 @property NSTimeInterval startTime;
 @property NSTimeInterval timeRemaining;
 
*/
@implementation WorkoutSection

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.beforeSound = [decoder decodeObjectForKey:@"beforeSound"];
    self.startSound = [decoder decodeObjectForKey:@"startSound"];
    self.name = [decoder decodeObjectForKey:@"name"];
    self.duration = [decoder decodeDoubleForKey:@"duration"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeDouble:self.duration forKey:@"duration"];
    [encoder encodeObject:self.startSound forKey:@"startSound"];
    [encoder encodeObject:self.beforeSound forKey:@"beforeSound"];
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
    WorkoutSection *newSection = [WorkoutSection sectionWithDuration:self.duration name:self.name];
    newSection.timeRemaining = self.timeRemaining;
    newSection.startSound = self.startSound;
    newSection.beforeSound = self.beforeSound;

    return newSection;
}

+ (WorkoutSection *)sectionWithDuration:(NSTimeInterval)duration name:(NSString *)name {
    WorkoutSection *newSection = [[WorkoutSection alloc] init];
    newSection.duration = duration;
    newSection.timeRemaining = duration;
    newSection.name = name;
    return newSection;
}

@end
