//
//  AboutViewController.m
//  WorkoutTimer
//
//  Created by Grant Kennell on 5/22/16.
//  Copyright © 2016 Grant Kennell. All rights reserved.
//

#import "AboutViewController.h"

#import "AnalyticsConstants.h"

@import Firebase;

#define ARTICLE_URL_STRING @"http://mobile.nytimes.com/blogs/well/2016/04/27/1-minute-of-all-out-exercise-may-equal-45-minutes-of-moderate-exertion"

@interface TopAlignedLabel : UILabel

@end

@implementation TopAlignedLabel

- (void)drawTextInRect:(CGRect)rect {
    if (self.text) {
        CGSize labelStringSize = [self.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                      attributes:@{NSFontAttributeName:self.font}
                                                         context:nil].size;
        [super drawTextInRect:CGRectMake(0, 0, ceilf(CGRectGetWidth(self.frame)),ceilf(labelStringSize.height))];
    } else {
        [super drawTextInRect:rect];
    }
}

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor blackColor].CGColor;
}

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mainTextLabel.adjustsFontSizeToFitWidth = YES;
    self.mainTextLabel.minimumScaleFactor = 0.5f;
    [self.mainTextLabel sizeToFit];
}

- (IBAction)openArticle:(id)sender {
    [FIRAnalytics logEventWithName:kReadArticlePressedAnalyticsKey parameters:nil];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ARTICLE_URL_STRING]];
}

- (IBAction)doneButonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
