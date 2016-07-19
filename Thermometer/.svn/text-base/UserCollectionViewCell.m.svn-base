//
//  UserCollectionViewCell.m
//  Thermometer
//
//  Created by Realank on 16/7/12.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "UserCollectionViewCell.h"
@interface UserCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end
@implementation UserCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews{
    [self updateDisplay];
}

- (void)updateDisplay{

    if (_displayType == CellTypeUser) {
        self.titleLabel.text = _userInfo.name;
        if (_choosen) {
            self.contentView.backgroundColor = [UIColor lightGrayColor];
        }else{
            self.contentView.backgroundColor = [UIColor darkGrayColor];
        }
        
    }else{
        self.titleLabel.text = @"+添加";
        self.titleLabel.textColor = self.tintColor;
    }

}

- (void)setDisplayType:(UserCollectionCellType)type{
    _displayType = type;
    
    [self updateDisplay];
}

@end
