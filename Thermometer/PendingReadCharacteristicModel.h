//
//  PendingReadCharacteristicModel.h
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTLEConnectModel.h"

@interface PendingReadCharacteristicModel : NSObject

@property (weak, nonatomic) CBService* serviceToWait;
@property (weak, nonatomic) CBCharacteristic* characteristicToWait;
@property (copy, nonatomic) ReadResultUpdateBlock readCallBackBlock;

@end
