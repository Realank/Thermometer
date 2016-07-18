//
//  BTLEConnectModel.m
//  Thermometer
//
//  Created by Realank on 16/7/13.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "BTLEConnectModel.h"
#import "PendingReadCharacteristicModel.h"
#import "DataProcessUtil.h"


#if 0
#define BTDLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define BTDLog(...)
#endif

@interface BTLEConnectModel ()<CBCentralManagerDelegate,CBPeripheralDelegate>{
    //系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
    CBCentralManager *manager;
}

@property (strong, nonatomic) NSMutableArray<CBPeripheral*>* btPeripheralsArray;//查找到的BT设备

@property (copy, nonatomic) NSArray<CBUUID*>* searchedBTServices;//要查找的BT设备需要包含的服务

@property (strong, nonatomic) CBPeripheral* connectedPeripheral;//在连接的BT设备

@property (strong, nonatomic) NSMutableArray<CBService*>* discoveredServices;//连接的BT设备，所具备的服务

@property (strong, nonatomic) NSMutableArray<PendingReadCharacteristicModel*>* pendingReadCharacteristicsArray;



/*
 (void(^)(CBPeripheral* btDevice))connectBlock failBlock:(void(^)(CBPeripheral* btDevice, NSError* error))failBlock disconnectBlock:(void(^)(CBPeripheral* btDevice, NSError* error))disconnectBlock
 */

@property (copy, nonatomic) void(^searchBTUpdateBlock)(NSArray* searchedBTDevices);

@property (copy, nonatomic) void(^connectBTBlock)(CBPeripheral* btDevice);
@property (copy, nonatomic) void(^failConnectBTBlock)(CBPeripheral* btDevice, NSError* error);
@property (copy, nonatomic) void(^disconnectBTBlock)(CBPeripheral* btDevice, NSError* error);

@end

@implementation BTLEConnectModel

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
        _btPeripheralsArray = [NSMutableArray array];
    }
    
    return self;
}

- (NSMutableArray *)discoveredServices{
    if (!_discoveredServices) {
        _discoveredServices = [NSMutableArray array];
    }
    return _discoveredServices;
}

- (NSMutableArray<CBPeripheral *> *)btPeripheralsArray{
    if (!_btPeripheralsArray) {
        _btPeripheralsArray = [NSMutableArray array];
    }
    return _btPeripheralsArray;
}

- (NSMutableArray<PendingReadCharacteristicModel *> *)pendingReadCharacteristicsArray{
    if (!_pendingReadCharacteristicsArray) {
        _pendingReadCharacteristicsArray = [NSMutableArray array];
    }
    return _pendingReadCharacteristicsArray;
}

#pragma mark - Package Methods
- (void)startSearchBTDeviceForServices:(NSArray<NSString *> *)serviceUUIDs withUpdate:(void(^)(NSArray* searchedBTDevices))searchUpdateBlock{
    
    
    if (manager) {
        [manager stopScan];
        manager = nil;
        
    }
    _btPeripheralsArray = nil;
    manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    
    NSMutableArray* serviceUUIDsArray = [NSMutableArray array];
    for (NSString* uuidString in serviceUUIDs) {
        CBUUID* uuid = [CBUUID UUIDWithString:uuidString];
        [serviceUUIDsArray addObject:uuid];
    }
    _searchedBTServices = [serviceUUIDsArray copy];
    _searchBTUpdateBlock = searchUpdateBlock;
}

- (void)stopSearchBTDevice{
    _searchBTUpdateBlock = nil;
    [manager stopScan];
}

- (void)tryConnectBTDevice:(CBPeripheral *)peripheral WithConnectBlock:(void(^)(CBPeripheral* btDevice))connectBlock failBlock:(void(^)(CBPeripheral* btDevice, NSError* error))failBlock disconnectBlock:(void(^)(CBPeripheral* btDevice, NSError* error))disconnectBlock{
    
    if (_connectedPeripheral) {
        if (![_connectedPeripheral.identifier.UUIDString isEqualToString: peripheral.identifier.UUIDString]) {
            [self disconnectBTDevice:_connectedPeripheral];
        }else{
            return;
        }
        
    }
    [self tryToConnectPeripheral:peripheral];
    _connectBTBlock = connectBlock;
    _failConnectBTBlock = failBlock;
    _disconnectBTBlock = disconnectBlock;
}


- (void)distroyConnectProperties{
    for (PendingReadCharacteristicModel* model in self.pendingReadCharacteristicsArray) {
        if (model.characteristicToWait) {
            [self cancelNotifyCharacteristic:_connectedPeripheral characteristic:model.characteristicToWait];
        }
        
    }
    _pendingReadCharacteristicsArray = nil;
    _connectedPeripheral = nil;
    _connectBTBlock = nil;
    _failConnectBTBlock = nil;
    _disconnectBTBlock = nil;
    _discoveredServices = nil;
    
}
- (void)disconnectBTDevice:(CBPeripheral *)peripheral{
    [self distroyConnectProperties];
    [self disconnectPeripheral:manager peripheral:peripheral];
    
}

- (BOOL)startReadDataFromBTDevice:(CBPeripheral*)peripheral
                       forService:(NSString*)serviceUUID
                andCharacteristic:(NSString*)characteristicUUID
                     resultUpdate:(ReadResultUpdateBlock) resultUpdateBlock{
    
    if (![peripheral.identifier.UUIDString isEqualToString:_connectedPeripheral.identifier.UUIDString]) {
        BTDLog(@"传入的外设与已连接的不符");
        return NO;
    }
    for (CBService* service in _discoveredServices) {
        if ([service.UUID.UUIDString isEqualToString:serviceUUID]) {
            for (CBCharacteristic* characteristic in service.characteristics) {
                if ([characteristic.UUID.UUIDString isEqualToString:characteristicUUID]) {
                    //handle resultUpdateBlock
                    PendingReadCharacteristicModel* readModel = [[PendingReadCharacteristicModel alloc]init];
                    readModel.serviceToWait = service;
                    readModel.characteristicToWait = characteristic;
                    readModel.readCallBackBlock = resultUpdateBlock;
                    [self.pendingReadCharacteristicsArray addObject:readModel];
                    [self notifyCharacteristic:peripheral characteristic:characteristic];
                    return YES;
                }
            }
        }
    }
    return NO;
}
- (void)endReadDataFromPeripheral:(CBPeripheral*)peripheral
                       forService:(NSString*)serviceUUID
                andCharacteristic:(NSString*)characteristicUUID{
    if (![peripheral.identifier.UUIDString isEqualToString:_connectedPeripheral.identifier.UUIDString]) {
        BTDLog(@"传入的外设与已连接的不符");
        return;
    }
    for (PendingReadCharacteristicModel* readModel in self.pendingReadCharacteristicsArray) {
        if ([serviceUUID isEqualToString:readModel.serviceToWait.UUID.UUIDString]) {
            if ([characteristicUUID isEqualToString:readModel.characteristicToWait.UUID.UUIDString]) {
                //bingo
                [self.pendingReadCharacteristicsArray removeObject:readModel];
            }
        }
    }
}

- (BOOL)canWriteDataToBTDevice:(CBPeripheral *)peripheral forService:(NSString*)serviceUUID andCharacteristic:(NSString*)characteristicUUID{
    if (![peripheral.identifier.UUIDString isEqualToString:_connectedPeripheral.identifier.UUIDString]) {
        BTDLog(@"传入的外设与已连接的不符");
        return NO;
    }
    
    for (CBService* service in _discoveredServices) {
        if ([service.UUID.UUIDString isEqualToString:serviceUUID]) {
            for (CBCharacteristic* characteristic in service.characteristics) {
                if ([characteristic.UUID.UUIDString isEqualToString:characteristicUUID]) {
                    
                    return [self canWriteCharacteristic:peripheral characteristic:characteristic];
                }
            }
        }
    }
    return NO;
}

- (BOOL)writeDataToBTDevice:(CBPeripheral *)peripheral forService:(NSString*)serviceUUID andCharacteristic:(NSString*)characteristicUUID value:(NSString *)hexString{
    
    if (![peripheral.identifier.UUIDString isEqualToString:_connectedPeripheral.identifier.UUIDString]) {
        BTDLog(@"传入的外设与已连接的不符");
        return NO;
    }
    
    for (CBService* service in _discoveredServices) {
        if ([service.UUID.UUIDString isEqualToString:serviceUUID]) {
            for (CBCharacteristic* characteristic in service.characteristics) {
                if ([characteristic.UUID.UUIDString isEqualToString:characteristicUUID]) {
                    //send data
                    NSData* data = [DataProcessUtil stringToByte:hexString];
                    return [self writeCharacteristic:peripheral characteristic:characteristic value:data];
                }
            }
        }
    }
    return NO;
}

#pragma mark - Core Bluetooth Methods
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state){
        case CBCentralManagerStateUnknown:
            BTDLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            BTDLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            BTDLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            BTDLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            BTDLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            BTDLog(@">>>CBCentralManagerStatePoweredOn");
            //开始扫描周围的外设
            [self scanBTDevice];
           
        }
            break;
        default:
            break;
    }
    
}

- (void)scanBTDevice{
    /*第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
             - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
     */
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [manager scanForPeripheralsWithServices:_searchedBTServices options:dic];
}

- (BOOL)addBtPeripheralToArray:(CBPeripheral*)peripheral{
    if (![self.btPeripheralsArray containsObject:peripheral] && peripheral.name.length > 0) {
        for (CBPeripheral* existPeripheral in self.btPeripheralsArray) {
            if ([existPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                return NO;
            }
        }
        
        [self.btPeripheralsArray addObject:peripheral];
        return YES;
    }
    return NO;
}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    BTDLog(@"扫描到设备:%@",peripheral.name);
    if ([self addBtPeripheralToArray:peripheral]) {
        if (_searchBTUpdateBlock) {
            _searchBTUpdateBlock([self.btPeripheralsArray copy]);
        }
    }

}

- (void)tryToConnectPeripheral:(CBPeripheral*)peripheral{
    //接下来可以连接设备
    //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
    
    /*
     一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
     - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
     - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
     - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
     */
    //连接设备
    
    [manager connectPeripheral:peripheral options:nil];
    
}

//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    BTDLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    
    _connectedPeripheral = peripheral;
    
    //设置的peripheral委托CBPeripheralDelegate
    //@interface ViewController : UIViewController
    [peripheral setDelegate:self];
    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral discoverServices:nil];
    
    if (_connectBTBlock) {
        _connectBTBlock(peripheral);
    }
    
}

//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    BTDLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
    if (_failConnectBTBlock) {
        _failConnectBTBlock(peripheral,error);
    }
    [self distroyConnectProperties];
    
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    BTDLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    if (_disconnectBTBlock) {
        _disconnectBTBlock(peripheral,error);
    }
    [self distroyConnectProperties];
}

//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    BTDLog(@">>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        BTDLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        BTDLog(@"UUID: %@",service.UUID);
        //扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    
    if (error)
    {
        BTDLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    //把发现特征值的服务，加入到已发现服务中
    if (_connectedPeripheral && ![self.discoveredServices containsObject:service]) {
        [self.discoveredServices addObject:service];
    }
    
//    for (CBCharacteristic *characteristic in service.characteristics)
//    {
//        //        NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
//        if ([characteristic.UUID.UUIDString isEqualToString:@"FFE9"]) {
//            NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
//            
//            //            NSLog(@"找到发送的特性");
//            
//            [self writeCharacteristic:peripheral characteristic:characteristic value:[self stringToByte:@"D0 A1 71"]];//@"00 00 00 00 00 00 00 00 00 00 D0 00 A1 00 00 00 00 00 00 61"
//        }else if ([characteristic.UUID.UUIDString isEqualToString:@"FFE4"]){
//            [self notifyCharacteristic:peripheral characteristic:characteristic];
//        }
//    }
    
    //获取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
//    for (CBCharacteristic *characteristic in service.characteristics){
//        {
//            [peripheral readValueForCharacteristic:characteristic];
//        }
//    }
    
    
    
}
//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    BTDLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);
    
    for (PendingReadCharacteristicModel* readModel in self.pendingReadCharacteristicsArray) {
        if ([characteristic.service.UUID.UUIDString isEqualToString:readModel.serviceToWait.UUID.UUIDString]) {
            if ([characteristic.UUID.UUIDString isEqualToString:readModel.characteristicToWait.UUID.UUIDString]) {
                //bingo
                if (readModel.readCallBackBlock) {
                    readModel.readCallBackBlock([DataProcessUtil hexadecimalString:characteristic.value]);
                }
            }
        }
    }
    
}

-(BOOL)canWriteCharacteristic:(CBPeripheral *)peripheral
               characteristic:(CBCharacteristic *)characteristic{
    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                              = 0x01,
     CBCharacteristicPropertyRead                                                   = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                   = 0x04,
     CBCharacteristicPropertyWrite                                                  = 0x08,
     CBCharacteristicPropertyNotify                                                 = 0x10,
     CBCharacteristicPropertyIndicate                                               = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                              = 0x40,
     CBCharacteristicPropertyExtendedProperties                                     = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x200
     };
     
     */
    BTDLog(@"%lu", (unsigned long)characteristic.properties);
    
    
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        
        return YES;
    }else{
        BTDLog(@"该字段不可写！");
        return NO;
    }
}

//写数据
-(BOOL)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    if ([self canWriteCharacteristic:peripheral characteristic:characteristic]) {
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        return YES;
    }else{
        return NO;
    }
    
    
}
//- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
//    NSLog(@"***begin<%s>***",__func__);
//    NSLog(@"characteristic uuid:%@ error:%@",characteristic.UUID,error);
//    
//    NSLog(@"***end***");
//}

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
}




@end
