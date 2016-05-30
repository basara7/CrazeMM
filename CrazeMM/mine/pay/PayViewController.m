//
//  MinePayViewController.m
//  CrazeMM
//
//  Created by saix on 16/4/25.
//  Copyright © 2016年 189. All rights reserved.
//

#import "PayViewController.h"
#import "FirstAddrCell.h"
#import "SecondProductDetailCell.h"
#import "LastPayMethodCell.h"
#import "TTModalView.h"
#import "PayAlertView.h"
#import "AddressListViewController.h"
#import "PayResultViewController.h"
#import "HttpOrderStatus.h"
#import "HttpAddress.h"
#import "HttpPay.h"
#import "PayInfoDTO.h"

#import "OnlinePayViewController.h"
#import "BuySlideDetailViewController.h"

typedef NS_ENUM(NSInteger, MinePayRow){
    kAddrRow = 1,
    kProductSumRow = 3,
    kPayWayRow = 5,
    kMaxPayRow
};

@interface PayViewController ()

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) FirstAddrCell* addrCell;
@property (nonatomic, strong) UITableViewCell* addAddrCell;

@property (nonatomic, strong) SecondProductDetailCell* productDetailCell;
@property (nonatomic, strong) LastPayMethodCell* payWayCell;

@property (nonatomic, strong) UIView* bottomView;
@property (nonatomic, strong) UIButton* confirmButton;

@property (nonatomic, strong) TTModalView* confirmModalView;
@property (nonatomic, strong) PayAlertView* payAlertView;

@property (nonatomic, strong) OrderStatusDTO* orderStatusDto;
@property (nonatomic, copy) NSArray<OrderDetailDTO*>* orderDetailDtos;
@property (nonatomic, readonly) BOOL needHiddenAddrCell;
@property (nonatomic, copy) NSArray* addresses;
@property (nonatomic, readonly) CGFloat totalPrice;
@property (nonatomic, strong) AddressDTO* selectedAddrDto;
@property (nonatomic, strong) PayInfoDTO* payInfoDto;

@end


@implementation PayViewController

-(CGFloat)totalPrice
{
    CGFloat totalPrice = 0.f;
    for(OrderDetailDTO* dto in self.orderDetailDtos)
    {
        totalPrice += dto.quantity * dto.price;
    }
    
    return totalPrice;
}

-(instancetype)initWithOrderStatusDTO:(OrderStatusDTO *)orderStatusDto
{
    self = [super init];
    if (self) {
        self.orderStatusDto = orderStatusDto;
        self.orderDetailDtos = @[
                                 [[OrderDetailDTO alloc] initWithOrderStatusDTO:orderStatusDto]
                                 ];
        
    }
    return self;
}

-(instancetype)initWithOrderDetailDTOs:(NSArray<OrderDetailDTO*>*)orderStatusDtos
{
    self = [super init];
    if (self) {
        self.orderDetailDtos = orderStatusDtos;
    }
    return self;
}

-(void)getOrderAddresses
{
    HttpAddressRequest* request = [[HttpAddressRequest alloc] init];
    [request request]
    .then(^(id responseObj){
        HttpAddressResponse* response = (HttpAddressResponse*)request.response;
        if (response.ok) {
            self.addresses = response.addresses;
            self.selectedAddrDto = self.addresses.firstObject;
            [self.tableView reloadData];
        }
        else {
            [self showAlertViewWithMessage:response.errorMsg];
        }
    })
    .catch(^(NSError* error){
        [self showAlertViewWithMessage:error.localizedDescription];
    });
}

-(void)getOneOrderStatusDto
{
    if (self.orderStatusDto) {
        return;
    }
    
    HttpOrderStatusRequest* request = [[HttpOrderStatusRequest alloc] initWithOrderId:self.orderDetailDtos.firstObject.id andOderType:kOrderTypeBuy];
    [request request]
    .then(^(id responseObj){
        HttpOrderStatusResponse* response = (HttpOrderStatusResponse*)request.response;
        if (response.ok) {
            self.orderStatusDto = response.orderStatusDto;
            [self.tableView reloadData];
        }
        else {
            [self showAlertViewWithMessage:response.errorMsg];
        }
    })
    .catch(^(NSError* error){
        [self showAlertViewWithMessage:error.localizedDescription];
    });
    
}

-(BOOL)needHiddenAddrCell
{
//    if (self.orderStatusDto == nil) {
//        return YES;
//    }
//    
//    if (!self.orderStatusDto.addr || [self.orderStatusDto.addr isKindOfClass:[NSNull class]]) {
//        return YES;
//    }
    
    return NO;
}

-(UIButton*)confirmButton
{
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _confirmButton.backgroundColor = [UIColor redColor];
        [_confirmButton setTitle:@"确认支付" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:18.f];
        
        @weakify(self);
        _confirmButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
            @strongify(self);
            
            
            HttpPayInfoRequest* request = [[HttpPayInfoRequest alloc] initWithPayPrice:self.totalPrice];
            [request request]
            .then(^(id responseObj){
                NSLog(@"%@", responseObj);
                HttpPayInfoResponse* response = (HttpPayInfoResponse*)request.response;
                if (response.ok) {
                    self.payInfoDto = response.payInfoDto;
                    self.confirmModalView.modalWindowFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
                    self.confirmModalView.presentAnimationStyle = fadeIn;
                    self.confirmModalView.dismissAnimationStyle = fadeOut ;
                    
                    self.payAlertView.totalPriceLabel.text = [NSString stringWithFormat:@"%.02f", self.productDetailCell.totalPrice];
                    self.payAlertView.orderNoLabel.text = self.payInfoDto.ORDERID;
                    
                    [self.confirmModalView showWithDidAddContentBlock:^(UIView *contentView) {
                        
                        contentView.centerX = self.view.centerX;
                        contentView.centerY = self.view.centerY;
                        
                        
                        self.payAlertView.dismissButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
                            @strongify(self);
                            [self.confirmModalView dismiss];
                            
                            return [RACSignal empty];
                        }];
                        
                        self.payAlertView.confirmButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
                            @strongify(self);
                            [self.confirmModalView dismiss];
                            
//                            PayResultViewController* payResultVC = [[PayResultViewController alloc] init];
//                            
//                            [self.navigationController pushViewController:payResultVC animated:YES];
                            
                            return [RACSignal empty];
                        }];
                        
                        
                    }];
                }
                else {
                    [self showAlertViewWithMessage:response.errorMsg];
                }
                
            })
            .catch(^(NSError* error){
                [self showAlertViewWithMessage:error.localizedDescription];
            });
            
            
            return [RACSignal empty];
        }];
    }
    return _confirmButton;
}

-(UIView*)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        [_bottomView addSubview:self.confirmButton];
        [self.view addSubview:_bottomView];
    }
    
    return _bottomView;
}

-(UITableViewCell*)addAddrCell
{
    if (!_addAddrCell) {
        _addAddrCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"addAddrCell"];
        _addAddrCell.textLabel.text = @"请先创建您的收货地址";
        _addAddrCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return _addAddrCell;
}

-(FirstAddrCell*) addrCell
{
    if (!_addrCell) {
        _addrCell = [[[NSBundle mainBundle]loadNibNamed:@"FirstAddrCell" owner:nil options:nil] firstObject];
        @weakify(self);
        _addrCell.detailButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
            @strongify(self);
            AddressListViewController *addrVC = [[AddressListViewController alloc] init];
            [self.navigationController pushViewController:addrVC animated:YES];

//            @strongify(self);
//            HttpAddressDetailRequest* request = [[HttpAddressDetailRequest  alloc] init];
//            [request request]
//            .then(^(id responseObj){
//                HttpAddressDetailResponse* response = (HttpAddressDetailResponse*)request.response;
//                if (response.ok) {
//                    AddressListViewController *addrVC = [[AddressListViewController alloc] initWithAddresses:response.addresses];;
//                    [self.navigationController pushViewController:addrVC animated:YES];
//                }
//                else {
//                    [self showAlertViewWithMessage:response.errorMsg];
//                }
//            })
//            .catch(^(NSError* error){
//                [self showAlertViewWithMessage:error.localizedDescription];
//            });
            
            return [RACSignal empty];
        }];
    }
    return _addrCell;
}

-(SecondProductDetailCell*)productDetailCell
{
    if (!_productDetailCell) {
        _productDetailCell = [[SecondProductDetailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SecondProductDetailCell"];
    }
    
    return _productDetailCell;
}


-(LastPayMethodCell*)payWayCell
{
    if (!_payWayCell) {
        _payWayCell = [[[NSBundle mainBundle]loadNibNamed:@"LastPayMethodCell" owner:nil options:nil] firstObject];
    }
    
    return _payWayCell;
}

-(TTModalView*)confirmModalView
{
    if (!_confirmModalView) {
        _confirmModalView = [[TTModalView alloc] initWithContentView:nil delegate:nil];;
        _confirmModalView.isCancelAble = YES;
        _confirmModalView.modalWindowLevel = UIWindowLevelNormal;
        _confirmModalView.contentView = self.payAlertView;
    }
    
    return _confirmModalView;
}

-(PayAlertView*)payAlertView
{
    if (!_payAlertView) {
        _payAlertView = [[[NSBundle mainBundle]loadNibNamed:@"PayAlertView" owner:nil options:nil] firstObject];
        _payAlertView.layer.cornerRadius = 6.f;
        [_payAlertView.confirmButton addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _payAlertView;
}

-(void)pay
{
    AddressDTO* addr = self.selectedAddrDto;
    HttpPayRequest* payRequest = [[HttpPayRequest alloc] initWithPayNo:self.payInfoDto.ORDERID andOrderId:self.orderStatusDto.id andAddrId:addr.id];
    [payRequest request]
    .then(^(id responseObj){
        NSLog(@"%@", responseObj);
        if (payRequest.response.ok) {
            OnlinePayViewController* vc = [[OnlinePayViewController alloc] initWithPayInfoDto:self.payInfoDto];
            vc.orderDetailDtos = self.orderDetailDtos;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            [self showAlertViewWithMessage:payRequest.response.errorMsg];
        }
    })
    .catch(^(NSError* error){
        [self showAlertViewWithMessage:error.localizedDescription];
    });
    
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"确认订单";
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = RGBCOLOR(240, 240, 240);
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self getOneOrderStatusDto];
    [self getOrderAddresses];

    
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.bottomView.frame = CGRectMake(0, self.view.bounds.size.height-45, self.view.bounds.size.width, 45);
    self.confirmButton.frame = self.bottomView.bounds;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return kMaxPayRow;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell* cell;
    if (indexPath.row == kAddrRow) {
        if (self.addresses.count == 0) {
            cell = self.addAddrCell;
        }
        else {
            cell = self.addrCell;
            self.addrCell.addrDto = self.selectedAddrDto;
        }
    }
    else if(indexPath.row== kProductSumRow){
        cell = self.productDetailCell;
        self.productDetailCell.orderDetailDtos = self.orderDetailDtos;

    }
    else if(indexPath.row == kPayWayRow){
        cell = self.payWayCell;
    }
    else {
        cell = [[UITableViewCell alloc] init];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    return cell;
}



//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 40.f;
//}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row== kAddrRow) {
        if (self.addresses.count>0) {
            return [FirstAddrCell cellHeight];
        }
        else {
            return 60.f;
        }

    }
    else if(indexPath.row== kProductSumRow){
        return self.productDetailCell.height;
    }
    else if(indexPath.row == kPayWayRow){
        return [LastPayMethodCell cellHeight];
    }
    
    else {
        if (indexPath.row ==0 && self.needHiddenAddrCell) {
            return 0;
        }
        return 16.f;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row== kAddrRow) {
        AddressesViewController *addrVC = [[AddressesViewController alloc] init];
        addrVC.delegate = self;
        [self.navigationController pushViewController:addrVC animated:YES];
        
    }
    else {
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma -- mark AddressListViewController Delegate
-(void)didSelectedAddress:(AddrDTO *)address
{
    self.selectedAddrDto = [[AddressDTO alloc] initWithAddr:address];
}


@end
