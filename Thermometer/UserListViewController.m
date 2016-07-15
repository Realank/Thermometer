//
//  UserListViewController.m
//  Thermometer
//
//  Created by Realank on 16/7/13.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "UserListViewController.h"
#import "UserInfo.h"

@interface UserListViewController ()

@property (strong, nonatomic, readonly) NSArray* users;

@end

@implementation UserListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"用户列表";
    UIBarButtonItem* rightBar = [[UIBarButtonItem alloc]initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(addUser)];
    self.navigationItem.rightBarButtonItem = rightBar;
}

- (void)addUser{
    
        UIAlertController* vc = [UIAlertController alertControllerWithTitle:@"添加用户" message:@"请输入用户名称" preferredStyle:UIAlertControllerStyleAlert];
        [vc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"用户名称";
        }];
        __block typeof(self) weakSelf = self;
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString* newUserName = vc.textFields.firstObject.text;
            UserInfo* user = [[UserInfo alloc]init];
            user.name = newUserName;
            [UsersList addUserToRom:user];
            [weakSelf.tableView reloadData];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.view endEditing:YES];
        }];
        [vc addAction:confirm];
        [vc addAction:cancel];
        [self presentViewController:vc animated:YES completion:nil];

}

- (NSArray *)users{
    return [UsersList usersFromRom];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    
    UserInfo* userInfo = self.users[indexPath.row];
    cell.textLabel.text = userInfo.name;
    cell.detailTextLabel.text = userInfo.remarks;
    
    if (indexPath.row == [UsersList choosenIndex]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return self.users.count > 1;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        UserInfo* userInfo = self.users[indexPath.row];
        [UsersList removeUserFromRom:userInfo];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    }
}



#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row != [UsersList choosenIndex]) {
        [UsersList setChoosenIndex:indexPath.row];
        [tableView reloadData];
    }
}


@end
