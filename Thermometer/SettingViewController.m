//
//  SettingViewController.m
//  Thermometer
//
//  Created by Realank on 16/7/13.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "SettingViewController.h"
#import "UserListViewController.h"
#import "SearchBTViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 44.0;
}



#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    // Configure the cell...
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"用户列表";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 1:
            cell.textLabel.text = @"蓝牙列表";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            //用户列表
        {
            UserListViewController *vc = [[UserListViewController alloc]init];

            [self.navigationController pushViewController:vc animated:YES];
        }
            
            break;
        case 1:
            //蓝牙列表
        {
            SearchBTViewController *vc = [[SearchBTViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        default:
            break;
    }
}


@end
