//
//  HistoryViewController.m
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "HistoryViewController.h"
#import "UserInfo.h"

@interface HistoryViewController ()

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"历史数据";
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userInfo.historyDatas.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    NSArray* historydatas = self.userInfo.historyDatas;
    NSInteger index = indexPath.row;
    HistoryTemperatureData* data = historydatas[historydatas.count -1 - index];
    cell.textLabel.text = data.temperature;
    cell.detailTextLabel.text = data.dateString;
    return cell;
}



@end
