//
//  FDDeviceManagement.m
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "FDDeviceManagement.h"

@implementation FDDeviceManagement

+(instancetype) sharedInstance {
    static dispatch_once_t pred;
    static id shared = nil; //设置成id类型的目的，是为了继承
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

-(instancetype) initUniqueInstance {
    
    if (self = [super init]) {
        _connectStatus = FDDisConnect;
    }
    
    return self;
}


- (void)searchBT{
    self.btDevicesArray = nil;
    __weak typeof(self) weakSelf = self;
    
    [[FDComUtil sharedInstance] startSearchBTDeviceWithUpdate:^(NSArray<FDModel *> *searchedBTDevices) {
        weakSelf.btDevicesArray = searchedBTDevices;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FD_SCANED_NEW_BT_DEVICES object:nil];
    }];
}

- (void)stopSearchBT{
    [[FDComUtil sharedInstance] stopSearchBTDevice];
}

- (void)connectBT:(FDModel*)device{
    
    __weak typeof(self) weakSelf = self;
    _connectStatus = FDDisConnect;
    [[FDComUtil sharedInstance]tryConnectBTDevice:device withConnectBlock:^(FDModel *device) {
        weakSelf.connectStatus = FDConnectSuccess;
        weakSelf.connnectedDevice = device;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FD_CONNECT_STATUS object:nil];
    } receivedDataBlock:^(FDRcvDataType dataType, NSArray<FDDataModel *> *dataArray) {
        weakSelf.lastReadDataArray = dataArray;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FD_CONNECT_NEW_DATA object:nil];
        
    } failBlock:^(FDModel *device, NSError *error) {
        weakSelf.connectStatus = FDConnectFail;
        [weakSelf destroyConnectData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FD_CONNECT_STATUS object:nil];
    } disconnectBlock:^(FDModel *device, NSError *error) {
        weakSelf.connectStatus = FDDisConnect;
        [weakSelf destroyConnectData];
//        [weakSelf stopSearchBT];
        [weakSelf searchBT];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FD_CONNECT_STATUS object:nil];
        
    }];
}

- (void)destroyConnectData{
    self.connnectedDevice = nil;
    self.lastReadDataArray = nil;
}

- (void)disconnectBT:(FDModel*)device{
    self.connectStatus = FDDisConnect;
    [self destroyConnectData];
    [[FDComUtil sharedInstance] disconnectBTDevice:device];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FD_CONNECT_STATUS object:nil];
}


@end
