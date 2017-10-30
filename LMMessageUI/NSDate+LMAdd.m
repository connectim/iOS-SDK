//
//  NSDate+LMAdd.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/10/9.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "NSDate+LMAdd.h"
#import <YYKit/YYKit.h>

@implementation NSDate (LMAdd)

/* 时间转文案 */
- (NSString *)messageTime {

    long long timeNow = [[NSDate date] timeIntervalSince1970];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    [calendar setFirstWeekday:2];
    
    NSInteger unitFlags = NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday;
    NSDateComponents *component = [calendar components:unitFlags fromDate:self];
    
    NSInteger year = [component year];
    NSInteger month = [component month];
    NSInteger day = [component day];
    
    NSDate *today = [NSDate date];
    component = [calendar components:unitFlags fromDate:today];
    
    NSInteger t_year = [component year];
    NSInteger t_month = [component month];
    NSInteger t_day = [component day];
    
    NSString *string = nil;
    
    long long now = [today timeIntervalSince1970];
    
    long long distance = now - timeNow;
    
    if (distance <= 60 * 60 * 24 && day == t_day && t_month == month && t_year == year) {
        
        string = [NSString stringWithFormat:NSLocalizedString(@"Today %@", nil), [self stringWithFormat:@"HH:mm"]];
        
    } else if (day == t_day - 1 && t_month == month && t_year == year) {
        
        string = [NSString stringWithFormat:NSLocalizedString(@"Yesterday %@", nil), [self stringWithFormat:@"HH:mm"]];
        
    } else if (day == t_day - 2 && t_month == month && t_year == year) {
        
        string = [NSString stringWithFormat:NSLocalizedString(@"The day before yesterday %@", nil), [self stringWithFormat:@"HH:mm"]];
        
    } else if (year == t_year) {
        NSString *detailTime = [self stringWithFormat:@"HH:mm"];
        string = [NSString stringWithFormat:@"%ld/%ld  %@", (long) month, (long) day, detailTime];
        
    } else {
        NSString *detailTime = [self stringWithFormat:@"HH:mm"];
        string = [NSString stringWithFormat:@"%ld/%ld/%ld  %@", (long) month, (long) day, (long) year, detailTime];
    }
    return string;
}


@end
