//
//  HomeTableViewCell.h
//  Veteris
//
//  Created by electimon on 1/5/24.
//  Copyright (c) 2024 1pwn. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface HomeTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *headlineLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

+ (CGFloat)heightForContentText:(NSString *)text tableWidth:(CGFloat)tableWidth;



@end
