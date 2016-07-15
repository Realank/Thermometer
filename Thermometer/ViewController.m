//
//  ViewController.m
//  Thermometer
//
//  Created by Realank on 16/7/12.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "ViewController.h"
#import "UserCollectionViewCell.h"
#import "UserInfo.h"
#import "FDDeviceManagement.h"
#import "HistoryViewController.h"

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *battaryStatusLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *userCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *connectedBTNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sampleTimeLabel;

@property (strong, nonatomic, readonly) NSArray* users;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configCollectioView];
    self.connectedBTNameLabel.text = @"未连接";
    self.connectedBTNameLabel.textColor = [UIColor grayColor];
    self.battaryStatusLabel.hidden = YES;
    self.sampleTimeLabel.hidden = YES;
    [self addNotification];
    [[FDDeviceManagement sharedInstance] searchBT];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.userCollectionView reloadData];
    
    if ([UsersList usersFromRom].count > 2) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[UsersList choosenIndex] inSection:0];
        [_userCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
    
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectBTStatusChanged) name:NOTIFICATION_FD_CONNECT_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newBtDataCome) name:NOTIFICATION_FD_CONNECT_NEW_DATA object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanedNewBt) name:NOTIFICATION_FD_SCANED_NEW_BT_DEVICES object:nil];
}

- (void)scanedNewBt{
    if ([FDDeviceManagement sharedInstance].connectStatus != FDConnectSuccess) {
        NSString* lastConnectDeviceID = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastConnectDeviceID"];

        FDModel* newestDevice = [FDDeviceManagement sharedInstance].btDevicesArray.lastObject;
        if ([newestDevice.deviceID isEqualToString:lastConnectDeviceID]) {
            [[FDDeviceManagement sharedInstance] connectBT:newestDevice];
        }

    }
}

- (void)connectBTStatusChanged{

    if ([FDDeviceManagement sharedInstance].connectStatus == FDConnectSuccess) {
        self.connectedBTNameLabel.text = [NSString stringWithFormat:@"已连接:%@",[FDDeviceManagement sharedInstance].connnectedDevice.deviceName];
        self.connectedBTNameLabel.textColor = [UIColor greenColor];
    }else{
        self.connectedBTNameLabel.text = @"未连接";
        self.connectedBTNameLabel.textColor = [UIColor grayColor];
    }
}

- (void)newBtDataCome{
    NSArray* dataArray = [FDDeviceManagement sharedInstance].lastReadDataArray;
    if (dataArray.count == 1) {
        FDDataModel* data = dataArray[0];
        if (data.dataType == FDRcvDataRT) {
            CGFloat temperature = data.temperature;
            self.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℃",temperature];
            self.battaryStatusLabel.hidden = NO;
            if (data.volt == 0xc3) {
                self.battaryStatusLabel.text = @"电池状态：良好";
            }else if (data.volt == 0xc4) {
                self.battaryStatusLabel.text = @"电池状态：低电";
            }else{
                self.battaryStatusLabel.text = @"电池状态：未知";
            }
            NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"HH:mm:ss"];
            self.sampleTimeLabel.text = [formatter stringFromDate:data.measureDate];
            self.sampleTimeLabel.hidden = NO;
            [[UsersList currentUser] appendDataToHistory:data];
        }
    }
}

- (void)configCollectioView{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(150, 45);
    NSInteger space = (self.view.bounds.size.width - 2*150)/3;
    space = space > 5 ? space : 5;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = space;
    layout.sectionInset = UIEdgeInsetsMake(5, 10, 5, 10);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.userCollectionView.collectionViewLayout = layout;
    self.userCollectionView.delegate = self;
    self.userCollectionView.dataSource = self;
    [self.userCollectionView registerNib:[UINib nibWithNibName:@"UserCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"UserCollectionViewCell"];
}

- (NSArray *)users{
    return [UsersList usersFromRom];
}

#pragma mark - UICollectionView Delegate & DataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UserCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserCollectionViewCell" forIndexPath:indexPath];
    cell.choosen = (indexPath.row == [UsersList choosenIndex]);
    if (indexPath.row < [self.users count]) {
        cell.displayType = CellTypeUser;
        cell.userInfo = self.users[indexPath.row];
        
    }else{
        cell.displayType = CellTypeAdd;
    }
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.users count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    NSArray* users = [UsersList usersFromRom];
    NSInteger index = indexPath.row;
    if (users.count > index) {
        UserInfo* userInfo = users[index];
        HistoryViewController* vc = [[HistoryViewController alloc]init];
        vc.userInfo = userInfo;
        [self.navigationController pushViewController:vc animated:YES];
    }

}
@end
