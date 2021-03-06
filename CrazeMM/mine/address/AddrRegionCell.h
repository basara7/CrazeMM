//
//  AddrRegionCell.h
//  CrazeMM
//
//  Created by saix on 16/5/17.
//  Copyright © 2016年 189. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SuggestViewController.h"

@interface AddrRegionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *regionLabel;
@property (weak, nonatomic) IBOutlet UIButton *chooseButton;
@property (weak, nonatomic) IBOutlet UIView *seperatorLine;

@property (nonatomic, strong) NSString* value;
@property (nonatomic, strong) NSString* title;

-(void)hideChooseButton;

-(void)popSelection:(NSArray*)options andDelegate:(id<SuggestVCDelegate>)delegate;
-(void)dismissSelection;

@end


