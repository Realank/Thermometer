//
//  FDComUtil.m
//  BTLEDemo
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "FDComUtil.h"
#import "BTLEConnectModel.h"
#import "DataProcessUtil.h"

#if 0
#define FDDLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define FDDLog(...)
#endif

@implementation FDDataModel

+ (instancetype)ModelWithHexString:(NSString *)hexString{
    NSInteger length = hexString.length;
    if ([hexString hasPrefix:@"D0"] && length >= 6 && length <= 20 && length % 2 == 0) {
        
        NSMutableArray* commandsArray = [NSMutableArray array];
        for (NSInteger i = 0; i < length/2; i++) {
            NSRange range = NSMakeRange(i * 2, 2);
            NSString* command = [hexString substringWithRange:range];
            [commandsArray addObject:command];
        }
        NSInteger commands[10] = {0};
        NSInteger commandsLength = 0;
        for (; commandsLength < commandsArray.count; commandsLength++) {
            commands[commandsLength] = [DataProcessUtil intFromHex:commandsArray[commandsLength]];
        }
        if([self checkSum:commands length:commandsLength]){
            //数据验证成功
            FDDataModel* model = [[FDDataModel alloc]init];
            if (commandsLength == 6 && (commands[1] == 0xa3 || commands[1] == 0xa4)) {
                NSInteger userNumber = 0;
                if (commands[1] == 0xa4) {
                    userNumber = 1;
                }
                NSInteger temperatureRaw = commands[2] * 0x100 + commands[3];
                model.temperature = temperatureRaw / 10 / 10.0f;
                model.dataType = FDRcvDataRT;
                model.volt = commands[4];
                model.userNumber = userNumber;
                model.measureDate = [NSDate date];
                return model;
            }
        }
        
    }
    return nil;
}

+ (BOOL)checkSum:(NSInteger*)commands length:(NSInteger)length{
    if (length < 3) {
        return NO;
    }
    NSInteger sum = 0;
    for (NSInteger i = 0; i < length-1; i++) {
        sum += commands[i];
    }
    if (sum % 0x100 == commands[length-1]) {
        return YES;
    }
    return NO;
}

@end

@implementation FDModel

- (instancetype)initWithPeripheral:(CBPeripheral*)peripheral{
    if (self = [super init]) {
        _peripheral = peripheral;
        NSString* uuidString = peripheral.identifier.UUIDString;
        NSString* name = peripheral.name;
        self.deviceName = name;
        self.deviceID = [NSString stringWithFormat:@"%@-%@",name,uuidString];
    }
    return self;
}

@end

@interface FDComUtil ()

@property (weak,nonatomic) ReceiveDataBlock receiveDataBlock;

@end

@implementation FDComUtil

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
        
    }
    
    return self;
}

- (void)startSearchBTDeviceWithUpdate:(void(^)(NSArray<FDModel*>* searchedBTDevices))searchUpdateBlock{
    [[BTLEConnectModel sharedInstance] startSearchBTDeviceForServices:nil withUpdate:^(NSArray *searchedBTDevices) {
        
        NSMutableArray* devices = [NSMutableArray array];
        for (CBPeripheral* peripheral in searchedBTDevices) {
            [devices addObject:[[FDModel alloc]initWithPeripheral:peripheral]];
        }
        if (searchUpdateBlock) {
            searchUpdateBlock([devices copy]);
        }
    }];
}

- (void)stopSearchBTDevice{
    [[BTLEConnectModel sharedInstance] stopSearchBTDevice];
}

- (void)tryConnectBTDevice:(FDModel *)device
          withConnectBlock:(void(^)(FDModel* device))connectBlock
         receivedDataBlock:(ReceiveDataBlock)receivedDataBlock
                 failBlock:(void(^)(FDModel* device, NSError* error))failBlock
           disconnectBlock:(void(^)(FDModel* device, NSError* error))disconnectBlock{
    
    __weak typeof(self) weakSelf = self;
    
    [[BTLEConnectModel sharedInstance]tryConnectBTDevice:device.peripheral WithConnectBlock:^(CBPeripheral *btDevice) {
        
        weakSelf.receiveDataBlock = receivedDataBlock;
        if (connectBlock) {
            connectBlock([[FDModel alloc] initWithPeripheral:btDevice]);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf readTemperatureFromDevice:btDevice times:0];
        });
    } failBlock:^(CBPeripheral *btDevice, NSError *error) {
        [self destoryConnectData];
        if (failBlock) {
            failBlock([[FDModel alloc] initWithPeripheral:btDevice], error);
        }
    } disconnectBlock:^(CBPeripheral *btDevice, NSError *error) {
        [self destoryConnectData];
        if (disconnectBlock) {
            disconnectBlock([[FDModel alloc] initWithPeripheral:btDevice], error);
        }
    }];
}

- (void)destoryConnectData{
    self.receiveDataBlock = nil;
}

- (void)readTemperatureFromDevice:(CBPeripheral*)peripheral times:(NSInteger)times{

    if([[BTLEConnectModel sharedInstance] startReadDataFromBTDevice:peripheral forService:@"FFE0" andCharacteristic:@"FFE4" resultUpdate:^(NSString *hexString) {
        FDDLog(@"Read:%@",hexString);
        [self handleReadData:hexString];
        
    }]){
        FDDLog(@"准备读取成功");
    }else{
        FDDLog(@"准备读取失败%ld次",(long)times);
        if (times < 5) {
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf readTemperatureFromDevice:peripheral times:times+1];
            });
        }
        
    }
    
}

- (void)handleReadData:(NSString*)hexString{
    FDDataModel* model = [FDDataModel ModelWithHexString:hexString];
    if (model && model.dataType == FDRcvDataRT) {
        if (_receiveDataBlock) {
            _receiveDataBlock(FDRcvDataRT,@[model]);
        }
    }
}


- (void)disconnectBTDevice:(FDModel*)device{
    [self destoryConnectData];
    [[BTLEConnectModel sharedInstance] disconnectBTDevice:device.peripheral];
}

@end
