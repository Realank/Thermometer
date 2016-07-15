//
//  FDDeviceManagement.h
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDComUtil.h"

#define NOTIFICATION_FD_SCANED_NEW_BT_DEVICES @"com.ihealth.fd.scan.new_bt"
#define NOTIFICATION_FD_CONNECT_STATUS @"com.ihealth.fd.connect.status"
#define NOTIFICATION_FD_CONNECT_NEW_DATA @"com.ihealth.fd.connect.new_data"

typedef NS_ENUM(NSUInteger, FDConnectStatus) {
    FDConnectSuccess,
    FDConnectFail,
    FDDisConnect,
};

@interface FDDeviceManagement : NSObject

@property (strong, nonatomic) NSArray<FDModel*>* btDevicesArray;
@property (assign, nonatomic) FDConnectStatus connectStatus;
@property (strong, nonatomic) FDModel* connnectedDevice;
@property (strong, nonatomic) NSArray<FDDataModel*>* lastReadDataArray;

+(instancetype) sharedInstance;
// clue for improper use (produces compile time error)
+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

- (void)searchBT;
- (void)stopSearchBT;
- (void)connectBT:(FDModel*)device;
- (void)disconnectBT:(FDModel*)device;

@end
