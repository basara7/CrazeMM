//
//  WaitForPayCell.h
//  CrazeMM
//
//  Created by saix on 16/4/24.
//  Copyright © 2016年 189. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BEMCheckBox.h"
#import "M80AttributedLabel.h"
#import "OrderDetailDTO.h"

@interface WrappedOrderDetailDTO : NSObject

@property (nonatomic) BOOL selected;
@property (nonatomic, weak) WaitForPayCell* cell;
@property (nonatomic, strong) OrderDetailDTO* dto;

-(instancetype)initWithOrderDetail:(OrderDetailDTO *)dto;

@end

@protocol OrderListCellDelegate <NSObject>

-(void)reactiveButtonClicked:(OrderDetailDTO*)orderDetailDTO;

@end


@interface OrderListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *reactiveButton;
@property (weak, nonatomic) IBOutlet BEMCheckBox *selectedCheckBox;
@property (weak, nonatomic) IBOutlet UILabel *orderLabel;
@property (weak, nonatomic) IBOutlet UIView *companyWithIconLabel;
@property (weak, nonatomic) IBOutlet UIView *seperatorLine;
@property (weak, nonatomic) IBOutlet UILabel *productDescLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLabel;

@property (weak, nonatomic) IBOutlet UIView *backgroundLabel;
@property (nonatomic) BOOL hiddenCheckbox;
@property (strong, nonatomic) OrderDetailDTO* orderDetailDTO;

@property (nonatomic, weak) id<OrderListCellDelegate> delegate;

+(CGFloat)cellHeight;

@end


