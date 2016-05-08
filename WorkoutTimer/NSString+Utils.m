//
//  NSString+Utils.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/5/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

+ (NSString *)stringWithTimeInterval:(NSTimeInterval)duration {
    NSInteger numSeconds = (NSInteger)round(duration) % 60;
    NSInteger numMinutes = (NSInteger)floor(duration / 60);
    return [NSString stringWithFormat:@"%02d:%02d", numMinutes, numSeconds];
}

@end
