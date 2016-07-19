//
//  SearchBTViewController.m
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "SearchBTViewController.h"
#import "FDDeviceManagement.h"

@interface SearchBTViewController ()

@end

@implementation SearchBTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
    self.title = @"正在搜索";
    [self searchBT];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[FDDeviceManagement sharedInstance] stopSearchBT];
}


- (void)searchBT{
//    [[FDDeviceManagement sharedInstance] searchBT];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FD_SCANED_NEW_BT_DEVICES object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanedNewBt) name:NOTIFICATION_FD_SCANED_NEW_BT_DEVICES object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FD_CONNECT_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectBTStatusChanged) name:NOTIFICATION_FD_CONNECT_STATUS object:nil];
}

- (void)scanedNewBt{
    [self.tableView reloadData];
}

- (void)connectBT:(FDModel*)device{
    
    [[FDDeviceManagement sharedInstance] connectBT:device];

    
}

- (void)connectBTStatusChanged{
    switch ([[FDDeviceManagement sharedInstance] connectStatus]) {
        case FDConnectSuccess:
        {
            self.title = @"连接成功";
            FDModel* connectedDevice = [FDDeviceManagement sharedInstance].connnectedDevice;
            if (connectedDevice && connectedDevice.deviceID.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:connectedDevice.deviceID forKey:@"lastConnectDeviceID"];
            }
            
        }
            break;
        case FDConnectFail:
            self.title = @"连接失败";
            break;
        case FDDisConnect:
            self.title = @"连接断开";
            break;
        default:
            break;
    }
    [self.tableView reloadData];
}

#pragma mark - TableView DataSource&Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    FDModel* device = [[FDDeviceManagement sharedInstance].btDevicesArray objectAtIndex:indexPath.row];
    FDModel* connectedDevice = [FDDeviceManagement sharedInstance].connnectedDevice;
    
    UITableViewCell* cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.textLabel.text = device.deviceName;
    if ([device.deviceID isEqualToString:connectedDevice.deviceID]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[FDDeviceManagement sharedInstance].btDevicesArray count];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FDModel* device = [[FDDeviceManagement sharedInstance].btDevicesArray objectAtIndex:indexPath.row];
    FDModel* connectedDevice = [FDDeviceManagement sharedInstance].connnectedDevice;
    if ([device.deviceID isEqualToString:connectedDevice.deviceID]) {
        [[FDDeviceManagement sharedInstance] disconnectBT:device];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"lastConnectDeviceID"];
    }else{
        [self connectBT:device];
    }
    
}


@end
