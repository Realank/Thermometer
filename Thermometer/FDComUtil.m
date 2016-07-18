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
            }else if (commandsLength == 5 && (commands[1] == 0xa5 || commands[1] == 0xa6)){
                NSInteger userNumber = 0;
                if (commands[1] == 0xa6) {
                    userNumber = 1;
                }
                NSInteger dataCount = commands[2];
                model.dataType = FDRcvDataHistoryCount;
                model.userNumber = userNumber;
                model.recordCount = dataCount;
                return model;
            }else if (commandsLength == 10 && (commands[1] == 0xa7 || commands[1] == 0xa8)){
                NSInteger userNumber = 0;
                if (commands[1] == 0xa8) {
                    userNumber = 1;
                }
                model.dataType = FDRcvDataHistory;
                NSInteger year = commands[2];
                NSInteger month = commands[3];
                NSInteger day = commands[4];
                NSInteger hour = commands[5];
                NSInteger minute = commands[6];
                NSInteger temperatureRaw = commands[7] * 0x100 + commands[8];
                NSString* dateString = [NSString stringWithFormat:@"%02d-%02d-%02d %02d:%02d",year,month,day,hour,minute];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat:@"yy-MM-dd HH:mm"];
                NSDate *date = [dateFormatter dateFromString:dateString];
//                FDDLog(@"User:%d Date:%@ tem:%d",userNumber,dateString,temperatureRaw);

                model.measureDate = date;
                model.userNumber = userNumber;
                model.temperature = temperatureRaw / 10 / 10.0f;
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

@property (copy,nonatomic) ReceiveDataBlock receiveDataBlock;
@property (copy,nonatomic) ReceiveDataBlock receivedHistoryDataBlock;
@property (assign,nonatomic) FDHistoryUserType receivedHistoryDataUserType;
@property (strong,nonatomic) NSMutableArray* receivedHistoryData1;
@property (strong,nonatomic) NSMutableArray* receivedHistoryData2;
@property (assign,nonatomic) NSInteger historyDataCountToReceive1;
@property (assign,nonatomic) NSInteger historyDataCountToReceive2;
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
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [weakSelf readTemperatureFromDevice:btDevice times:0];// notify read
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSDate* currentDate = [NSDate date];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSInteger unitFlags = NSCalendarUnitYear |
            NSCalendarUnitMonth |
            NSCalendarUnitDay |
            NSCalendarUnitHour |
            NSCalendarUnitMinute;
            NSDateComponents *comps = [calendar components:unitFlags fromDate:currentDate];
            
            NSInteger year = comps.year % 100;
            NSInteger month = comps.month;
            NSInteger day = comps.day;
            NSInteger hour = comps.hour;
            NSInteger min = comps.minute;
            NSInteger sum = (0xD0 + 0xA0 + year + month + day + hour + min) % 0x100;
            
            NSString* dateString = [NSString stringWithFormat:@"D0 A0 %02X %02X %02X %02X %02X %02X",year,month,day,hour,min,sum];
            
            if([[BTLEConnectModel sharedInstance] writeDataToBTDevice:btDevice forService:@"FFE5" andCharacteristic:@"FFE9" value:dateString]){
                //设置时间
                if (connectBlock) {
                    connectBlock([[FDModel alloc] initWithPeripheral:btDevice]);
                }
            }else{
                //如果不能设置时间，则不能连接
                [self disconnectBTDevice:device];
                if (failBlock) {
                    failBlock([[FDModel alloc] initWithPeripheral:btDevice], nil);
                }
            }
            
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
    self.receivedHistoryDataUserType = FDHisUserNone;
    self.receivedHistoryDataBlock = nil;
    self.receivedHistoryData1 = nil;
    self.receivedHistoryData2 = nil;
    self.historyDataCountToReceive1 = -1;
    self.historyDataCountToReceive2 = -1;
}

- (void)readTemperatureFromDevice:(CBPeripheral*)peripheral times:(NSInteger)times{

    __weak typeof(self) weakSelf = self;
    if([[BTLEConnectModel sharedInstance] startReadDataFromBTDevice:peripheral forService:@"FFE0" andCharacteristic:@"FFE4" resultUpdate:^(NSString *hexString) {
        FDDLog(@"Read:%@",hexString);
        [weakSelf handleReadData:hexString];
        
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
    if (model) {
        if (model.dataType == FDRcvDataRT) {
            if (_receiveDataBlock) {
                _receiveDataBlock(FDRcvDataRT,@[model]);
            }
        }else if (model.dataType == FDRcvDataHistoryCount){
            if (model.userNumber == 0) {
                _historyDataCountToReceive1 = model.recordCount;
                _receivedHistoryData1 = [NSMutableArray array];
            }else if (model.userNumber == 1){
                _historyDataCountToReceive2 = model.recordCount;
                _receivedHistoryData2 = [NSMutableArray array];
            }
        }else if (model.dataType == FDRcvDataHistory){
            NSInteger dataFullCount = -1;
            NSMutableArray* datasToSave = nil;
            if (model.userNumber == 0) {
                dataFullCount = _historyDataCountToReceive1;
                datasToSave = _receivedHistoryData1;
                
            }else if (model.userNumber == 1){
                dataFullCount = _historyDataCountToReceive2;
                datasToSave = _receivedHistoryData2;
            }
            
            if (dataFullCount > 0 && datasToSave) {
                [datasToSave addObject:model];
                if (datasToSave.count == dataFullCount) {
                    
                    NSMutableArray* datas;
                    
                    switch (_receivedHistoryDataUserType) {
                        case FDHisUserOne:
                        {
                            if (_historyDataCountToReceive1 == _receivedHistoryData1.count ) {
                                datas = [NSMutableArray array];
                                for (FDDataModel* dataModel in _receivedHistoryData1) {
                                    if (dataModel.measureDate && dataModel.temperature > 0) {
                                        [datas addObject:dataModel];
                                    }
                                }
 
                            }
                        }
                            break;
                        case FDHisUserTwo:
                        {
                            if (_historyDataCountToReceive2 == _receivedHistoryData2.count ) {
                                datas = [NSMutableArray array];
                                for (FDDataModel* dataModel in _receivedHistoryData2) {
                                    if (dataModel.measureDate && dataModel.temperature > 0) {
                                        [datas addObject:dataModel];
                                    }
                                }
                                
                            }
                        }
                            break;
                        case FDHisUserAll:
                        {
                            if (_historyDataCountToReceive1 == _receivedHistoryData1.count && _historyDataCountToReceive2 == _receivedHistoryData2.count ) {
                                datas = [NSMutableArray array];
                                for (FDDataModel* dataModel in _receivedHistoryData1) {
                                    if (dataModel.measureDate && dataModel.temperature > 0) {
                                        [datas addObject:dataModel];
                                    }
                                }
                                for (FDDataModel* dataModel in _receivedHistoryData2) {
                                    if (dataModel.measureDate && dataModel.temperature > 0) {
                                        [datas addObject:dataModel];
                                    }
                                }
                                
                            }
                        }
                            break;
                            
                        default:
                            break;
                    }
                    

                    if (datas &&  _receivedHistoryDataBlock) {
                        _receivedHistoryDataBlock(FDRcvDataHistory,datas);
                    }

                }
            }
        }
    }
    
}


- (BOOL)requestHistoryDataInDevice:(FDModel *)device forUserType:(FDHistoryUserType)userType withReceiveHistoryBlock:(ReceiveDataBlock)receivedHistoryDataBlock{
    
    _receivedHistoryDataBlock = receivedHistoryDataBlock;
    _receivedHistoryDataUserType = userType;
    _receivedHistoryData1 = nil;
    _receivedHistoryData2 = nil;
    _historyDataCountToReceive1 = -1;
    _historyDataCountToReceive2 = -1;
    
    
    NSString* serviceUUID = @"FFE5";
    NSString* characeristicUUID = @"FFE9";
    NSString* readUser1Commands = @"D0 A1 71";
    NSString* readUser2Commands = @"D0 A2 72";
    switch (userType) {
        case FDHisUserOne:
        {
            return [[BTLEConnectModel sharedInstance] writeDataToBTDevice:device.peripheral forService:serviceUUID andCharacteristic:characeristicUUID value:readUser1Commands];
        }
            break;
        case FDHisUserTwo:
        {
            return [[BTLEConnectModel sharedInstance] writeDataToBTDevice:device.peripheral forService:serviceUUID andCharacteristic:characeristicUUID value:readUser2Commands];
        }
            break;
        case FDHisUserAll:
        {
            
            if ([[BTLEConnectModel sharedInstance]canWriteDataToBTDevice:device.peripheral forService:serviceUUID andCharacteristic:characeristicUUID]) {
                
                [[BTLEConnectModel sharedInstance] writeDataToBTDevice:device.peripheral forService:serviceUUID andCharacteristic:characeristicUUID value:readUser1Commands];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[BTLEConnectModel sharedInstance] writeDataToBTDevice:device.peripheral forService:serviceUUID andCharacteristic:characeristicUUID value:readUser2Commands];
                });
                return YES;
            }else{
                return NO;
            }
        }
            break;
            
        default:
            break;
    }
    return NO;
    
}


- (void)disconnectBTDevice:(FDModel*)device{
    [self destoryConnectData];
    [[BTLEConnectModel sharedInstance] disconnectBTDevice:device.peripheral];
}

@end
