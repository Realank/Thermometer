//
//  UserInfo.h
//  Thermometer
//
//  Created by Realank on 16/7/12.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDDeviceManagement.h"

@interface HistoryTemperatureData : NSObject

@property (nonatomic, strong) NSString* temperature;
@property (nonatomic, strong) NSString* dateString;

- (instancetype)initWithFDDataModel:(FDDataModel*)model;
- (NSDictionary*)toDict;
+ (instancetype)modelWithDict:(NSDictionary*)dict;
@end

@interface UserInfo : NSObject

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* remarks;
@property (nonatomic, strong, readonly) NSMutableArray* historyDatas;

- (NSDictionary*)toDict;
+ (UserInfo*)userInfoWithDict:(NSDictionary*)dict;
- (void)appendDataToHistory:(FDDataModel*)model;

@end

@interface UsersList : NSObject

+(NSInteger)choosenIndex;
+(void)setChoosenIndex:(NSInteger)index;
+(NSArray*)usersFromRom;
+(UserInfo*)currentUser;
+(BOOL)addUserToRom:(UserInfo*)userInfo;
+(BOOL)removeUserFromRom:(UserInfo*)userInfo;

@end