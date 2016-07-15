//
//  BTLEConnectModel.h
//  Thermometer
//
//  Created by Realank on 16/7/13.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^ReadResultUpdateBlock)(NSString* hexString);

@interface BTLEConnectModel : NSObject

+(instancetype) sharedInstance;
// clue for improper use (produces compile time error)
+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

- (void)startSearchBTDeviceForServices:(NSArray<NSString *> *)serviceUUIDs withUpdate:(void(^)(NSArray* searchedBTDevices))searchUpdateBlock;
- (void)stopSearchBTDevice;

- (void)tryConnectBTDevice:(CBPeripheral *)peripheral WithConnectBlock:(void(^)(CBPeripheral* btDevice))connectBlock failBlock:(void(^)(CBPeripheral* btDevice, NSError* error))failBlock disconnectBlock:(void(^)(CBPeripheral* btDevice, NSError* error))disconnectBlock;

- (void)disconnectBTDevice:(CBPeripheral *)peripheral;

- (BOOL)startReadDataFromBTDevice:(CBPeripheral*)peripheral forService:(NSString*)serviceUUID andCharacteristic:(NSString*)characteristicUUID resultUpdate:(ReadResultUpdateBlock) resultUpdateBlock;
- (void)endReadDataFromPeripheral:(CBPeripheral*)peripheral forService:(NSString*)serviceUUID andCharacteristic:(NSString*)characteristicUUID;

- (BOOL)writeDataToBTDevice:(CBPeripheral *)peripheral forService:(NSString*)serviceUUID andCharacteristic:(NSString*)characteristicUUID value:(NSString *)hexString;

@end
