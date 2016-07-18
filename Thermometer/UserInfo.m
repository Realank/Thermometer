//
//  UserInfo.m
//  Thermometer
//
//  Created by Realank on 16/7/12.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "UserInfo.h"

@implementation HistoryTemperatureData

- (instancetype)initWithFDDataModel:(FDDataModel *)model{
    if (self = [super init]) {
        _temperature = [NSString stringWithFormat:@"%.1f",model.temperature];
        NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        _dateString = [formatter stringFromDate:model.measureDate];
        _date = model.measureDate;
    }
    return self;
}

- (NSDictionary*)toDict{
    return @{
             @"temperature":_temperature,
             @"date":_dateString
             };
}

+ (instancetype)modelWithDict:(NSDictionary*)dict{
    
    NSString* temperature = dict[@"temperature"];
    NSString* dateString = dict[@"date"];
    if (temperature && dateString) {
        HistoryTemperatureData* data = [[HistoryTemperatureData alloc]init];
        data.temperature = temperature;
        data.dateString = dateString;
        return data;
    }
    
    return nil;
}

- (void)setDateString:(NSString *)dateString{
    _dateString = dateString;
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    _date = [formatter dateFromString:dateString];
}

@end

@interface UserInfo ()

@property (nonatomic, strong) NSDate* acountCreateTime;
@property (nonatomic, strong) NSString* dbFileName;

@end

@implementation UserInfo


- (void)setName:(NSString *)name{
    _name = name;
    if (_acountCreateTime == nil) {
        _acountCreateTime = [NSDate date];
        NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
        NSString *dateString = [formatter stringFromDate:_acountCreateTime];
        _dbFileName = [[name stringByAppendingString:dateString] stringByAppendingPathExtension:@"csv"];
    }
}

- (NSDictionary*)toDict{
    return @{
             @"type":@"UserInfo",
             @"name":_name,
             @"remarks":_remarks ? _remarks : @"",
             @"acountCreateTime":_acountCreateTime,
             @"dbFilePath":_dbFileName
             };
}
+ (UserInfo*)userInfoWithDict:(NSDictionary*)dict{
    if ([[dict objectForKey:@"type"] isEqualToString:@"UserInfo"]) {
        NSString* name = [dict objectForKey:@"name"];
        NSString* remarks = [dict objectForKey:@"remarks"];
        NSDate* accountCreateTime = [dict objectForKey:@"acountCreateTime"];
        NSString* dbFilePath = [dict objectForKey:@"dbFilePath"];
        if (name && remarks && accountCreateTime && dbFilePath) {
            UserInfo* userInfo = [[UserInfo alloc]init];
            userInfo.name = name;
            userInfo.remarks = remarks;
            userInfo.acountCreateTime = accountCreateTime;
            userInfo.dbFileName = dbFilePath;
            [userInfo retriveHistoryDatasFromRom];
            return userInfo;
        }
    }
    return nil;
}

- (void)retriveHistoryDatasFromRom{
    
    _historyDatas = [NSMutableArray arrayWithArray:[self readLocalCSV:_dbFileName]];
//    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//    NSString* filePath = [documentsDirectory stringByAppendingPathComponent:_dbFileName];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//        NSArray* datasInRom = [[NSArray alloc]initWithContentsOfFile:filePath];
//        for (NSDictionary* dataDict in datasInRom) {
//            HistoryTemperatureData* dataModel = [HistoryTemperatureData modelWithDict:dataDict];
//            if (dataModel) {
//                [_historyDatas addObject:dataModel];
//            }
//        }
//    }
}

- (void)appendDataToHistory:(NSArray<FDDataModel*>*)models{
    
    if (models.count <= 0) {
        return;
    }
    if (!_historyDatas) {
        _historyDatas = [NSMutableArray array];
    }
    
    for (NSInteger i = models.count - 1; i >= 0; i--) {
        FDDataModel* model = models[i];
        BOOL hasSameDataInRom = NO;
        for (HistoryTemperatureData* historyData in _historyDatas) {
            if (fabs([model.measureDate timeIntervalSinceDate:historyData.date]) < 3 && fabs(model.temperature - [historyData.temperature doubleValue]) < 0.1) {
                //  same data
                hasSameDataInRom = YES;
                break;
            }
        }
        if (!hasSameDataInRom) {
            HistoryTemperatureData* data = [[HistoryTemperatureData alloc] initWithFDDataModel:model];
            [_historyDatas addObject:data];
        }
    }
    
//    [_historyDatas sortUsingComparator:^NSComparisonResult(HistoryTemperatureData*  _Nonnull obj1, HistoryTemperatureData*  _Nonnull obj2) {
//        if ([obj1.date timeIntervalSinceDate:obj2.date] > 0) {
//            return NSOrderedAscending;
//        }else{
//            return NSOrderedDescending;
//        }
//    }];
    
    //remove repeat data
    
    
    
//    NSMutableArray* dictArrayToSave = [NSMutableArray array];
//    for (HistoryTemperatureData* dataModel in _historyDatas) {
//        NSDictionary* dataDict = [dataModel toDict];
//        [dictArrayToSave addObject:dataDict];
//    }
    
//    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//    NSString* filePath = [documentsDirectory stringByAppendingPathComponent:_dbFileName];
//    [dictArrayToSave writeToFile:filePath atomically:YES];
    [self exportCSV:_dbFileName contentArray:_historyDatas];
}

- (void)removeCSV:(NSString*)fileName{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString* filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:nil];
}

- (void)exportCSV:(NSString *)fileName contentArray:(NSArray*)contentArray {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString* filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:nil];
    
    
    if (![fileManager createFileAtPath:filePath contents:nil attributes:nil]) {
        NSLog(@"不能创建文件");
    }
    
    NSOutputStream *output = [[NSOutputStream alloc] initToFileAtPath:filePath append:YES];
    [output open];
    
    
    if (![output hasSpaceAvailable]) {
        NSLog(@"没有足够可用空间");
    } else {
        
        
        for (HistoryTemperatureData* data in contentArray) {
            NSString *row = [NSString stringWithFormat:@"\"%@\";\"%@\"\n",data.temperature, data.dateString];
            const uint8_t *rowString = (const uint8_t *)[row cStringUsingEncoding:NSUTF8StringEncoding];
            NSInteger rowLength = [row lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            NSInteger result = [output write:rowString maxLength:rowLength];
            if (result <= 0) {
                NSLog(@"无法写入内容");
            }
        }

        
        [output close];
    }
}

- (NSArray*)readLocalCSV:(NSString *)fileName {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString* filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    NSString *contents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray* datas = [NSMutableArray array];
    NSInteger idx;
    for (idx = 0; idx < contentsArray.count; idx++){
        NSString* currentContent = [contentsArray objectAtIndex:idx];
//        NSLog(@"%@",currentContent);
        NSArray* components = [currentContent componentsSeparatedByString:@";"];
        if (components.count == 2) {
            NSString* temperature = components[0];
            NSString* dateString = components[1];
            temperature = [temperature stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            dateString = [dateString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            if (temperature.length > 0 && dateString.length > 0) {
                HistoryTemperatureData* data = [[HistoryTemperatureData alloc]init];
                data.temperature = temperature;
                data.dateString = dateString;
                [datas addObject:data];
            }
            
        }
    }
    return [datas copy];
}


@end


@interface UsersList ()

@property (strong,nonatomic) NSMutableArray* users;
@property (assign,nonatomic) NSInteger selectIndex;

@end

@implementation UsersList

+(instancetype) sharedInstance {
    static dispatch_once_t pred;
    static id shared = nil; //设置成id类型的目的，是为了继承
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

+ (NSString*) usersListSavePath{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsDirectory stringByAppendingPathComponent:@"FDUsersList.plist"];
}


-(instancetype) initUniqueInstance {
    
    if (self = [super init]) {
        _users = [NSMutableArray array];
        
        NSString* filePath = [UsersList usersListSavePath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSDictionary* usersListInRom = [[NSDictionary alloc]initWithContentsOfFile:filePath];
            NSString* selectIndex = usersListInRom[@"lastSelectedIndex"];
            NSArray* usersList = usersListInRom[@"users"];
            if (selectIndex && usersList.count > 0) {
                for (NSDictionary* userInfoDict in usersList) {
                    UserInfo* user = [UserInfo userInfoWithDict:userInfoDict];
                    if (user) {
                        [_users addObject:user];
                    }
                }
                _selectIndex = [selectIndex integerValue];
            }
        }
        
        if (_users.count <= 0) {
            UserInfo* user1 = [[UserInfo alloc]init];
            user1.name = @"用户一";
            [_users addObject:user1];
    
            UserInfo* user2 = [[UserInfo alloc]init];
            user2.name = @"用户二";
            [_users addObject:user2];
            [UsersList saveToPlist:_users withSelectIndex:0];
            _selectIndex = 0;
            
        }
        
        
    }
    
    return self;
}

+ (NSInteger)choosenIndex{
    return [[self sharedInstance] selectIndex];
}

+ (void)setChoosenIndex:(NSInteger)index{
    [[self sharedInstance] setSelectIndex:index];
    [self saveToPlist:[self usersFromRom] withSelectIndex:[self choosenIndex]];
}

+(NSArray*)usersFromRom{
    return [[[self sharedInstance] users] copy];
}

+ (UserInfo *)currentUser{
    NSArray* users = [self usersFromRom];
    NSInteger index = [self choosenIndex];
    if (users.count > index) {
        return [users objectAtIndex:index];
    }else{
        return nil;
    }
}

+(BOOL)addUserToRom:(UserInfo*)userInfo{
    for (UserInfo* existUser in [self usersFromRom]) {
        if ([userInfo.name isEqualToString:existUser.name]) {
            return NO;
        }
    }
    
    //add user
    [[[self sharedInstance] users] addObject:userInfo];
    [self saveToPlist:[[self sharedInstance] users]withSelectIndex:[self choosenIndex]];
    return YES;
}

+ (void) saveToPlist:(NSArray*)array withSelectIndex:(NSInteger)selectIndex{
    NSString* filePath = [self usersListSavePath];
    NSMutableArray* usersToSave = [NSMutableArray array];
    for (UserInfo* userModel in array) {
        NSDictionary* userDict = [userModel toDict];
        [usersToSave addObject:userDict];
    }
    NSDictionary* usersListDict = @{
                                    @"lastSelectedIndex":[NSString stringWithFormat:@"%ld",(long)selectIndex],
                                    @"users":usersToSave
                                    };
    [usersListDict writeToFile:filePath atomically:YES];
}

+(BOOL)removeUserFromRom:(UserInfo*)userInfo{
    for (NSInteger i = 0; i < [self usersFromRom].count; i++) {
        UserInfo* existUser = [self usersFromRom][i];
        if ([userInfo.name isEqualToString:existUser.name]) {
            
            [userInfo removeCSV:userInfo.dbFileName];
            
            [[[self sharedInstance] users] removeObject:existUser];
            if (i == [self choosenIndex]) {
                [self setChoosenIndex:0];
            }
            [self saveToPlist:[[self sharedInstance] users]withSelectIndex:[self choosenIndex]];
            
            return YES;
        }
    }
    return NO;
}


@end
