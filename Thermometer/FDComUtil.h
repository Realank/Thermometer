//
//  FDComUtil.h
//  BTLEDemo
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CBPeripheral;

typedef NS_ENUM(NSUInteger, FDRcvDataType) {
    FDRcvDataRT,
    FDRcvDataHistory,
    FDRcvDataHistoryCount
};
@class FDDataModel;
typedef void(^ReceiveDataBlock)(FDRcvDataType dataType, NSArray<FDDataModel*>* dataArray);

@interface FDDataModel : NSObject

@property (nonatomic, assign) CGFloat temperature;
@property (nonatomic, strong) NSDate* measureDate;
@property (nonatomic, assign) NSInteger volt;
@property (nonatomic, assign) NSInteger recordCount;
@property (nonatomic, assign) FDRcvDataType dataType;
@property (nonatomic, assign) NSInteger userNumber;

+ (instancetype)ModelWithHexString:(NSString*)hexString;

@end

@interface FDModel : NSObject //体温计外设模型

@property (nonatomic, strong) NSString* deviceID;
@property (nonatomic, strong) NSString* deviceName;
@property (nonatomic, strong, readonly) CBPeripheral* peripheral;

- (instancetype)initWithPeripheral:(CBPeripheral*)peripheral;

@end

@interface FDComUtil : NSObject

+(instancetype) sharedInstance;
// clue for improper use (produces compile time error)
+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

- (void)startSearchBTDeviceWithUpdate:(void(^)(NSArray<FDModel*>* searchedBTDevices))searchUpdateBlock;
- (void)stopSearchBTDevice;


- (void)tryConnectBTDevice:(FDModel *)device
          withConnectBlock:(void(^)(FDModel* device))connectBlock
         receivedDataBlock:(ReceiveDataBlock) receivedDataBlock
                 failBlock:(void(^)(FDModel* device, NSError* error))failBlock
           disconnectBlock:(void(^)(FDModel* device, NSError* error))disconnectBlock;
- (void)disconnectBTDevice:(FDModel*)device;



@end
