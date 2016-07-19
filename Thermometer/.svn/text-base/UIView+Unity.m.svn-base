//
//  UIView+Unity.m
//  Thermometer
//
//  Created by Realank on 16/7/12.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "UIView+Unity.h"

@implementation UIView (Unity)

-(void)setCornerRadious:(CGFloat)radious{
    self.layer.cornerRadius = radious;
    self.layer.masksToBounds = YES;
}

-(CGFloat)cornerRadious{
    return self.layer.cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth{
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth{
    return self.layer.borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor{
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}
@end
