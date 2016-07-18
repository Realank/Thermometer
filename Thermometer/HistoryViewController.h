//
//  HistoryViewController.h
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <UIKit/UIKit.h>
@class UserInfo;
@interface HistoryViewController : UITableViewController

typedef NS_ENUM(NSUInteger, ShowHistoryType) {
    ShowUserOneHistory,
    ShowUserTwoHistory,
    ShowCustomUserHistory
};

@property (nonatomic,assign) ShowHistoryType showUserType;

@end
