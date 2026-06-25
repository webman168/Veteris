//
//  HomeViewController.h
//  Veteris
//
//  Created by electimon on 1/2/24.
//  Copyright (c) 2024 1pwn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsKit/Controllers/IASKAppSettingsViewController.h"

@interface HomeViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,IASKSettingsDelegate,UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIImageView *badgeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *appIconImageView;


@end
