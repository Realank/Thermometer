//
//  HistoryViewController.m
//  Thermometer
//
//  Created by Realank on 16/7/14.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "HistoryViewController.h"
#import "UserInfo.h"
#import "FDDeviceManagement.h"
#import "MBProgressHUD.h"

@interface HistoryViewController ()

@property (weak, nonatomic) UIBarButtonItem* rightBar;
@property (weak, nonatomic) MBProgressHUD* hud;
@property (strong, nonatomic) NSArray* dataArray;

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"历史数据";
   
    if (_showUserType == ShowCustomUserHistory) {
        UIBarButtonItem* rightBar = [[UIBarButtonItem alloc]initWithTitle:@"同步" style:UIBarButtonItemStylePlain target:self action:@selector(syncData)];
        _rightBar = rightBar;
        self.navigationItem.rightBarButtonItem = rightBar;
        self.dataArray = [UsersList currentUser].historyDatas;
    }else{
        [self syncData];
    }
    
}

- (void)syncData{
    
    FDHistoryUserType requestUserType = FDHisUserNone;
    switch (_showUserType) {
        case ShowUserOneHistory:
            requestUserType = FDHisUserOne;
            break;
        case ShowUserTwoHistory:
            requestUserType = FDHisUserTwo;
            break;
        case ShowCustomUserHistory:
            requestUserType = FDHisUserAll;
            break;
    }
    __weak typeof(self) weakSelf = self;
    BOOL readSuccess = [[FDDeviceManagement sharedInstance] readHistoryDataFromDevice:[FDDeviceManagement sharedInstance].connnectedDevice forUserType:requestUserType withResultBlock:^(FDRcvDataType dataType, NSArray<FDDataModel *> *dataArray) {
        if (weakSelf.showUserType == ShowCustomUserHistory) {
            [[UsersList currentUser] appendDataToHistory:dataArray];
            weakSelf.dataArray = [UsersList currentUser].historyDatas;
        }else{
            NSMutableArray* datas = [NSMutableArray array];
            for (NSInteger i = dataArray.count - 1; i >= 0; i--) {
                FDDataModel* model = dataArray[i];
                HistoryTemperatureData* data = [[HistoryTemperatureData alloc]initWithFDDataModel:model];
                if (data) {
                    [datas addObject:data];
                }
            }
            weakSelf.dataArray = [datas copy];
        }
        [weakSelf.tableView reloadData];
//        for (FDDataModel* model in dataArray) {
//            NSLog(@"tem:%f,date:%@",model.temperature,model.measureDate);
//            
//        }
        [weakSelf hideHUD];
    }];
    
    if (readSuccess) {
        [self loadingHUDWithCancelation];
    }else{
        [self showHUDWithText:@"无法获取"];
    }
}

- (void)showHUDWithText:(NSString*)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    
    [hud hideAnimated:YES afterDelay:2.f];
}

- (void)loadingHUDWithCancelation {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    // Set the determinate mode to show task progress.
//    hud.mode = MBProgressHUDModeDeterminate;
//    hud.label.text = NSLocalizedString(@"Loading...", @"HUD loading title");
    
    // Configure the button.
    [hud.button setTitle:@"Cancel" forState:UIControlStateNormal];
    [hud.button addTarget:self action:@selector(cancelWork:) forControlEvents:UIControlEventTouchUpInside];
    
    _hud = hud;
}

- (void)hideHUD{
    [_hud hideAnimated:YES];
}


- (void)cancelWork:(id)sender {
    [self hideHUD];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    NSInteger index = indexPath.row;
    HistoryTemperatureData* data = _dataArray[_dataArray.count - 1 - index];
    cell.textLabel.text = data.temperature;
    cell.detailTextLabel.text = data.dateString;
    return cell;
}



@end
