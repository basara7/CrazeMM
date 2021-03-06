//
//  MineSellProductViewController.m
//  CrazeMM
//
//  Created by saix on 16/4/24.
//  Copyright © 2016年 189. All rights reserved.
//

#import "OrderListViewController.h"
#import "OrderListCell.h"
#import "SegmentedCell.h"
#import "CommonBottomView.h"
#import "PayViewController.h"
#import "OrderListNoCheckBoxCell.h"
#import "HttpOrder.h"
#import "MJRefresh.h"
#import "OrderDetailViewController.h"
#import "HttpOrderRemove.h"
#import "HttpOrderOperation.h"
#import "OrderSendViewController.h"
#import "HttpOrderCancel.h"


#define kSegmentCellHeight 40.f
#define kTableViewInsetTopWithoutSegment (kSegmentCellHeight+64)


@interface OrderListViewController ()

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) SegmentedCell* segmentCell;
@property (nonatomic, strong) CommonBottomView* commonBottomView;
@property (nonatomic) NSInteger currentSegmentIndex;
@property (nonatomic, strong) NSMutableArray* dataSource;

@property (nonatomic) MMOrderType orderType;
@property (nonatomic) MMOrderSubType subType;
@property (nonatomic) MMOrderState orderState;

@property (nonatomic, readonly) MMOrderListStyle orderListStyle;

@property (nonatomic) NSInteger orderListPageNumber;
@property (nonatomic) NSInteger orderListTotalPage;

@property (nonatomic) CGFloat totalPrice;

@property (nonatomic, strong) UITableViewCell* emptyCell;
@property (nonatomic) CGPoint ptLastOffset;

@property (nonatomic) BOOL isRefreshing;

@end

@implementation OrderListViewController

//-(UITableViewCell*)emptyCell
//{
//    if (!_emptyCell) {
//        _emptyCell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 0, [UIScreen mainScreen].bounds.size.height)];
//        
//        _emptyCell
//    }
//}

-(MMOrderListStyle)orderListStyle
{
    MMOrderListStyle style;
    style.orderType = self.orderType;
    style.orderSubType = self.subType;
    style.orderState = self.orderState;
    
    return style;
}

-(NSArray*)getSegmentTitels
{
    switch (self.orderType) {
        case kOrderTypeBuy:
        {
            switch (self.subType) {
                case kOrderSubTypePay:
                    return @[@"待支付", @"超时", @"已支付"];
                    break;
                case kOrderSubTypeReceived:
                    return @[@"待签收", @"已签收"];
                    break;
                default:
                    break;
            }
        }
            break;
        case kOrderTypeSupply:
        {
            switch (self.subType) {
                case kOrderSubTypeSend:
                    return @[@"待支付", @"待发货", @"已发货"];
                    
                    break;
                case kOrderSubTypeConfirmed:
                    return @[@"待结款", @"待确认", @"完成"];
                    
                    break;
                    
                default:
                    break;
            }
        }
        default:
            
            break;
    }
    
    return @[@"待支付", @"超时", @"已支付"];
}

-(CommonBottomView*)commonBottomView
{
    if(!_commonBottomView){
        _commonBottomView = [[[NSBundle mainBundle]loadNibNamed:@"CommonBottomView" owner:nil options:nil] firstObject];
;
        [self.view addSubview:_commonBottomView];
        [_commonBottomView.confirmButton addTarget:self action:@selector(handleButtomButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _commonBottomView.selectAllCheckBox.delegate = self;
    }
    
    return _commonBottomView;
}

-(SegmentedCell*)segmentCell
{
    if(!_segmentCell){
        _segmentCell = [[SegmentedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SegmentedCell"];
        _segmentCell.buttonStyle = kButtonStyleB;
        _segmentCell.height = @(44.0f);
        _segmentCell.segment.delegate = self;
        [self.view addSubview:_segmentCell];
    }
    
    return _segmentCell;
}

-(instancetype)initWithOrderType:(MMOrderType)orderType andSubType:(MMOrderSubType)subType
{
    self = [super init];
    if (self) {
        self.orderType = orderType;
        self.subType = subType;
        if (orderType == kOrderTypeBuy) {
            if (subType == kOrderSubTypePay) {
                self.orderState = TOBEPAID;
            }
            else if(subType == kOrderSubTypeReceived)
            {
                self.orderState = TOBERECEIVED;
            }
        }
        else {
            if (subType == kOrderSubTypeSend) {
                //self.orderState = TOBESENT;
                self.orderState = WAITFORPAY;
            }
            else if(subType == kOrderSubTypeConfirmed)
            {
                self.orderState = TOBESETTLED;
            }
        }
    }
    return self;
}

-(BOOL)isMixed:(NSArray*)selectedDtos
{
    if (selectedDtos.count==0) {
        return NO;
    }
    
    OrderDetailDTO* firstDto = selectedDtos[0];
    BOOL hasStock = NO;
    if (firstDto.stock) {
        hasStock = YES;
    }
    
    for (OrderDetailDTO* dto in selectedDtos){
        if (dto.stock) {
            if (!hasStock) {
                return YES;
            }
        }
    }
    
    return NO;
}

-(void)handleButtomButtonClicked:(UIButton*)send
{
    NSInteger segmentIndex = self.segmentCell.segment.currentIndex;
    NSMutableArray* operatorDtos = [[NSMutableArray alloc] init];
    NSMutableArray* operatorDtoIds = [[NSMutableArray alloc] init];
    
    for (OrderDetailDTO* dto in self.dataSource) {
        if (dto.selected) {
            [operatorDtos addObject:dto];
            [operatorDtoIds addObject:[NSString stringWithFormat:@"%ld", dto.id]];
        }
    }
    
    @weakify(self);
    if (self.orderType == kOrderTypeBuy) {
        switch (self.subType ) {
            case kOrderSubTypePay:
            {
                switch (segmentIndex) {
                    case 0:
                    {
                        NSLog(@"我买的货->待付款->付款");
                        
                        if (operatorDtos.count == 0) {
                            [self showAlertViewWithMessage:@"请选择待付款的商品"];
                            break;
                        }
                        
                        if ([self isMixed:operatorDtos]) {
                            [self showAlertViewWithMessage:@"不支持将卖家发货的订单与库存订单合并支付"];
                            break;
                        }
                        
                        PayViewController* payVC = [[PayViewController alloc] initWithOrderDetailDTOs:operatorDtos];
                        [self.navigationController pushViewController:payVC animated:YES];
                    }
                        break;
                    case 1:
                    {
                        NSLog(@"我买的货->待付款->超时");
                        
                        if (operatorDtos.count == 0) {
                            [self showAlertViewWithMessage:@"请选择需要删除的订单"];
                            break;
                        }
                        [self showAlertViewWithMessage:[NSString stringWithFormat:@"确定要删除选中的%ld条订单吗?", operatorDtos.count]
                                        withOKCallback:^(id x){
                                            @strongify(self);
                                            HttpOrderRemoveRequest* request = [[HttpOrderRemoveRequest alloc] initWithOrderIds:operatorDtoIds];
                                            [request request]
                                            .then(^(id responseObj){
                                                NSLog(@"%@", responseObj);
                                                if (request.response.ok) {
                                                    for (OrderDetailDTO* dto in operatorDtos){
                                                        [self.dataSource removeObject:dto];
                                                    }
                                                    [self.tableView reloadData];
                                                }
                                                else {
                                                    [self showAlertViewWithMessage:request.response.errorMsg];
                                                }
                                            })
                                            .catch(^(NSError* error){
                                                [self showAlertViewWithMessage:error.localizedDescription];
                                            });
                                    }
                                     andCancelCallback:nil];
                    }
                        break;
                    case 2:
                    {
                        NSLog(@"我买的货->待付款->已支付");
                    }
                        break;
                    default:
                        break;
                }
            }
                break;
            case kOrderSubTypeReceived:
                switch (segmentIndex) {
                    case 0:
                    {
                        NSLog(@"我买的货->待签收->签收");
                        if (operatorDtos.count == 0) {
                            [self showAlertViewWithMessage:@"请选择需要签收的订单"];
                            break;
                        }
                        [self showAlertViewWithMessage:[NSString stringWithFormat:@"确定要签收选中的%ld条订单吗?", operatorDtos.count]
                                        withOKCallback:^(id x){
                                            @strongify(self);
                                            HttpOrderReceiveRequest* request = [[HttpOrderReceiveRequest alloc] initWithOids:operatorDtoIds];
                                            [request request]
                                            .then(^(id responseObj){
                                                NSLog(@"%@", responseObj);
                                                if (request.response.ok) {
                                                    for (OrderDetailDTO* dto in operatorDtos){
                                                        [self.dataSource removeObject:dto];
                                                    }
                                                    [self.tableView reloadData];
                                                }
                                                else {
                                                    [self showAlertViewWithMessage:request.response.errorMsg];
                                                }
                                            })
                                            .catch(^(NSError* error){
                                                [self showAlertViewWithMessage:error.localizedDescription];
                                            });
                                        }
                                     andCancelCallback:nil];

                    }
                        break;
                    case 1:
                        NSLog(@"我买的货->待签收->已签收");
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }
    }
    else if(self.orderType == kOrderTypeSupply){
        switch (self.subType ) {
            case kOrderSubTypeSend:
                switch (segmentIndex) {
                    case 0:
                        NSLog(@"我卖的货->待发货->待付款");
                        break;
                    case 1:
                    {
                        NSLog(@"我卖的货->待发货->发货");
                        if (operatorDtos.count == 0) {
                            [self showAlertViewWithMessage:@"请选择需要发货的订单"];
                            break;
                        }

                        OrderSendViewController* sendVC = [[OrderSendViewController alloc] initWithOrderDetaildtos:operatorDtos];
                        sendVC.delegate = self;
                        [self.navigationController pushViewController:sendVC animated:YES];
                    }
                        break;
                    case 2:
                        NSLog(@"我卖的货->待发货->已发货");
                        break;
                    default:
                        break;
                }
                break;
            case kOrderSubTypeConfirmed:
                switch (segmentIndex) {
                    case 0:
                        NSLog(@"我卖的货->待确认->待结款");
                        break;
                    case 1:
                    {
                        NSLog(@"我卖的货->待确认->待确认");
                        if (operatorDtos.count == 0) {
                            [self showAlertViewWithMessage:@"请选择需要确认的订单"];
                            break;
                        }
                        [self showAlertViewWithMessage:[NSString stringWithFormat:@"确定要确认选中的%ld条订单吗?", operatorDtos.count]
                                        withOKCallback:^(id x){
                                            @strongify(self);
                                            HttpOrderConfirmRequest* request = [[HttpOrderConfirmRequest alloc] initWithOids:operatorDtoIds];
                                            [request request]
                                            .then(^(id responseObj){
                                                NSLog(@"%@", responseObj);
                                                if (request.response.ok) {
                                                    for (OrderDetailDTO* dto in operatorDtos){
                                                        [self.dataSource removeObject:dto];
                                                    }
                                                    [self.tableView reloadData];
                                                }
                                                else {
                                                    [self showAlertViewWithMessage:request.response.errorMsg];
                                                }
                                            })
                                            .catch(^(NSError* error){
                                                [self showAlertViewWithMessage:error.localizedDescription];
                                            });
                                        }
                                     andCancelCallback:nil];
                    }
                        break;
                    case 2:
                        NSLog(@"我卖的货->待确认->完成");
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }
    }
}

//-(BOOL)isMixed:(NSArray*)selectedOrders
//{
//    
//}

-(void)setIsRefreshing:(BOOL)isRefreshing
{
    _isRefreshing = isRefreshing;
    
    for (UIButton* button in self.segmentCell.segment.buttons) {
        button.enabled = !isRefreshing;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.orderType==kOrderTypeBuy? @"我买的货" : @"我卖的货";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = RGBCOLOR(240, 240, 240);
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"OrderListCell" bundle:nil] forCellReuseIdentifier:@"OrderListCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"OrderListNoCheckBoxCell" bundle:nil] forCellReuseIdentifier:@"OrderListNoCheckBoxCell"];
    
//    self.tableView.tableHeaderView = self.segmentCell;
    self.currentSegmentIndex = 0;
    self.dataSource = [[NSMutableArray alloc] init];
    self.segmentCell.frame = CGRectMake(0, 64.f, [UIScreen mainScreen].bounds.size.width, kSegmentCellHeight);
    self.tableView.frame = self.view.bounds;
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    self.tableView.contentInset = UIEdgeInsetsMake(kSegmentCellHeight, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(kSegmentCellHeight, 0, 0, 0);

    
    
    @weakify(self);
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self);
        if (self.isRefreshing) {
            [self.tableView.mj_header endRefreshing];
            return;
        }
        self.isRefreshing = YES;
        [self getOrderList]
        .finally(^(){
            self.isRefreshing = NO;
            [self.tableView.mj_header endRefreshing];
        });
        
    }];
    
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
    
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        @strongify(self);
        if (self.isRefreshing) {
            [self.tableView.mj_footer endRefreshing];
            return;
        }
        self.isRefreshing = YES;
        [self getOrderList].finally(^(){
            self.isRefreshing = NO;
            [self.tableView.mj_footer endRefreshing];
        });
        
    }];
    self.tableView.mj_footer.automaticallyChangeAlpha = YES;

    self.isRefreshing = NO;
    [self setOrderStyleWithSegmentIndex:0];
    [self.segmentCell setTitles:[self getSegmentTitels]];
    [self getOrderList];

}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
//    self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.commonBottomView.frame = CGRectMake(0, self.view.height-[CommonBottomView cellHeight], self.view.bounds.size.width, [CommonBottomView cellHeight]);
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    self.orderListPageNumber = 0;
    [self.tabBarController setTabBarHidden:YES animated:YES];
    
    [self.tableView reloadData];
    self.commonBottomView.selectAllCheckBox.on = YES;
    if (self.dataSource.count == 0){
        self.commonBottomView.selectAllCheckBox.on = NO;
    }
    for (OrderDetailDTO* dto  in self.dataSource) {
        if (!dto.selected) {
            self.commonBottomView.selectAllCheckBox.on = NO;
            break;
        }
    }
    [self refreshTotalPriceLabel];
}

-(void)removeOrderDtoByOderIds:(NSArray*)ids
{
    NSMutableArray* temp = [self.dataSource mutableCopy];
    [self.dataSource removeAllObjects];
    for (OrderDetailDTO* dto in temp) {
        if (![ids containsObject:@(dto.id)]) {
            [self.dataSource addObject:dto];
        }
    }
    
    [self.tableView reloadData];
}

-(void)clearOrderList
{
    self.dataSource = [@[] mutableCopy];
    [self.tableView reloadData];
    self.orderListPageNumber = 0;
}

-(void)refreshTotalPriceLabel
{
    if (!self.commonBottomView.totalPriceLabel.hidden) {
        self.totalPrice = 0.f;
        for (NSInteger index = 0; index<self.dataSource.count; ++index) {
            OrderDetailDTO* dto = self.dataSource[index];
            if (dto.selected) {
                self.totalPrice += dto.price*dto.quantity;
            }
        }
        self.commonBottomView.totalPrice = self.totalPrice;
    }
}

-(AnyPromise*)getOrderList
{
    HttpOrderRequest* orderRequest = [[HttpOrderRequest alloc] initWithOrderListType:self.orderListStyle andPage:self.orderListPageNumber+1];
    return [orderRequest request]
    .then(^(id responseObject){
        NSLog(@"%@", responseObject);
        HttpOrderResponse* response = (HttpOrderResponse*)orderRequest.response;
        if (response.ok) {
            self.orderListTotalPage = response.totalPage;
            if (self.orderListPageNumber < self.orderListTotalPage) {
                self.orderListPageNumber = response.pageNumber;
            }
            if (response.orderDetailDTOs.count > 0) {
                [self.dataSource addObjectsFromArray:response.orderDetailDTOs];
                [self.tableView reloadData];
                [self refreshTotalPriceLabel];
                self.commonBottomView.selectAllCheckBox.on = NO;
            }
        }
    })
    .catch(^(NSError* error){
        [self showAlertViewWithMessage:error.localizedDescription];
    });
}

-(void)setOrderStyleWithSegmentIndex:(NSUInteger)index
{
    MMOrderListStyle style;
    self.currentSegmentIndex = index;
    style.orderType = self.orderType;
    style.orderSubType = self.subType;
    
    if (self.orderType == kOrderTypeBuy) {
        if (self.subType == kOrderSubTypePay) {
            switch (index) {
                case 0: // 待支付
                    style.orderState = TOBEPAID;
                    break;
                case 1: // 支付超时
                    style.orderState = PAYTIMEOUT;
                    break;
                case 2: // 已支付
                    style.orderState = PAYCOMPLETE;
                    break;
                default:
                    break;
            }
        }
        else if(self.subType == kOrderSubTypeReceived){
            switch (index) {
                case 0: //待签收
                    style.orderState = TOBERECEIVED;
                    break;
                case 1: //已签收
                    style.orderState = RECEIVECOMPLETE;
                    break;
                default:
                    break;
            }
        }
    }
    else if (self.orderType == kOrderTypeSupply){
        if (self.subType == kOrderSubTypeSend) {
            switch (index) {
                case 0: // 待付款
                    style.orderState = WAITFORPAY;
                    break;
                case 1: // 待发货
                    style.orderState = TOBESENT;
                    break;
                case 2: // 已发货
                    style.orderState = SENTCOMPLETE;
                    break;
                default:
                    break;
            }
        }
        else if(self.subType == kOrderSubTypeConfirmed){
            switch (index) {
                case 0: //待结款
                    style.orderState = TOBESETTLED;
                    break;
                case 1: //待确认
                    style.orderState = TOBECONFIRMED;
                    break;
                case 2: //已确认
                    style.orderState = CONFIRMEDCOMPLETE;
                    break;
                default:
                    break;
            }
        }
    }
    self.orderState = style.orderState;
    self.commonBottomView.orderStyle = style;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.dataSource.count+1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == self.dataSource.count) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"lastUselessCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"lastUselessCell"];
            cell.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        return cell;
    }
    
    OrderDetailDTO* dto = (OrderDetailDTO*)self.dataSource[indexPath.row];
    OrderListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OrderListCell"];
    if ((self.currentSegmentIndex == 1 &&
         (self.orderType==kOrderTypeBuy && self.subType == kOrderSubTypePay))
        ) {
            cell.reactiveButton.hidden = NO;
        [cell.reactiveButton setTitle:@"重新激活" forState:UIControlStateNormal];

    }
    else if((self.currentSegmentIndex==0 && (self.orderType==kOrderTypeBuy && self.subType == kOrderSubTypePay))){
        cell.reactiveButton.hidden = NO;
        [cell.reactiveButton setTitle:@"撤销" forState:UIControlStateNormal];
    }
    else {
        cell.reactiveButton.hidden = YES;
    }
    cell.selectedCheckBox.tag = 10000 + indexPath.row;
    cell.hiddenCheckbox = self.commonBottomView.hidden;
    cell.selectedCheckBox.on = dto.selected;
    cell.orderDetailDTO = dto;
    cell.selectedCheckBox.delegate = self;
    cell.delegate = self;

    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.dataSource.count) {
        return self.commonBottomView.height;
    }
    
    return [OrderListCell cellHeight]; //WaitForDeliverCell has the same height with WaitForPayCell
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{

    if (indexPath.row == self.dataSource.count) {
        return;
    }
    
    OrderDetailViewController* orderDetailVC = [[OrderDetailViewController alloc] initWithOrderStyle:self.orderListStyle andOrder:self.dataSource[indexPath.row]];
    orderDetailVC.delegate = self;
    [self.navigationController pushViewController:orderDetailVC animated:YES];
}

#pragma -- mark custom segment delegate

- (void)segment:(CustomSegment *)segment didSelectAtIndex:(NSInteger)index;
{
    if (segment.prevIndex == index) {
        return;
    }
    [self setOrderStyleWithSegmentIndex:index];
    [self clearOrderList];
    [self getOrderList];
}

#pragma -- mark BEMCheckBox Delegate
-(void)didTapCheckBox:(BEMCheckBox *)checkBox
{
    if (checkBox != self.commonBottomView.selectAllCheckBox) {
        NSInteger index = checkBox.tag - 10000;
        OrderDetailDTO* dto = self.dataSource[index];
        dto.selected = checkBox.on;

        NSArray* onArray = [self.dataSource filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.selected != NO"]];
        if (onArray.count == self.dataSource.count) {
            self.commonBottomView.selectAllCheckBox.on = YES;
        }
        else {
            self.commonBottomView.selectAllCheckBox.on = NO;
        }
    }
    else {
        for (NSInteger index = 0; index<self.dataSource.count; ++index) {
            OrderDetailDTO* dto = self.dataSource[index];
            dto.selected = checkBox.on;
        }
        [self.tableView reloadData];
    }
    
    [self refreshTotalPriceLabel];
}

#pragma -- mark UIScroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    if (scrollView == self.tableView){
        
        if (scrollView.isTracking && scrollView.dragging)
        {
            CGPoint ptOffset = scrollView.contentOffset;
            
            if (scrollView.contentSize.height >= scrollView.size.height) //内容高度大于view高度
            {
                if (ptOffset.y >= scrollView.contentSize.height - scrollView.size.height) //已经到最下方
                    return;
            }
            
            
            
            if (scrollView.contentInset.top == kTableViewInsetTopWithoutSegment)
            {
                if (ptOffset.y > -kTableViewInsetTopWithoutSegment) //下滑
                {
                    if ((ptOffset.y - self.ptLastOffset.y) > 0)
                    {
                        [self hideTopBars];
                        
                        self.ptLastOffset = ptOffset;
                        self.tableView.showsVerticalScrollIndicator = YES;
                    }
                    else
                    {
                        [self showTopBars];
                        self.ptLastOffset = ptOffset;
                    }
                }
            }
            else if (scrollView.contentInset.top == 0)
            {
                if (ptOffset.y > 0)
                {
                    if ((ptOffset.y - self.ptLastOffset.y) > 0)
                    {
                        [self hideTopBars];
                        
                        self.ptLastOffset = ptOffset;
                    }
                    else if ((ptOffset.y - self.ptLastOffset.y) < 0)
                    {
                        [self showTopBars];
                        self.ptLastOffset = ptOffset;
                    }
                }
                else if (ptOffset.y < 0)
                {
                    [self showTopBars];
                    self.ptLastOffset = ptOffset;
                }
            }
        }
    }
}

- (void)hideTopBars
{
    if (self.tableView.contentSize.height < self.tableView.height)
        return;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.segmentCell.transform = CGAffineTransformMakeTranslation(0, -300);
        
    } completion:^(BOOL finished) {
    }];
}

- (void)showTopBars
{
    self.tableView.contentInset = UIEdgeInsetsMake(kTableViewInsetTopWithoutSegment, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(kTableViewInsetTopWithoutSegment, 0, 0, 0);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.segmentCell.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
    
    
}


#pragma -- make OrderDetailViewController delegate
-(void)removeOrder:(OrderDetailDTO *)orderDto
{
    if(self.dataSource){
        [self.dataSource removeObject:orderDto];
        [self.tableView reloadData];
    }
}

-(void)cancelOrder:(OrderDetailDTO *)orderDto
{
    if(self.dataSource){
        [self.dataSource removeObject:orderDto];
        [self.tableView reloadData];
    }
}

-(void)operatorDoneForOrder:(NSArray *)orderDtos
{
    if(self.dataSource){
        [self.dataSource removeObjectsInArray:orderDtos];
        [self.tableView reloadData];
    }
}

#pragma -- mark order list cell delegate
-(void)reactiveButtonClicked:(OrderDetailDTO *)orderDetailDTO
{
    
    if ((self.currentSegmentIndex == 1 &&
         (self.orderType==kOrderTypeBuy && self.subType == kOrderSubTypePay))
        ) {
        @weakify(self);
        [self showAlertViewWithMessage:[NSString stringWithFormat:@"确认要激活订单: %ld 吗?", orderDetailDTO.id]
                        withOKCallback:^(id x){
                            @strongify(self);
                            HttpOrderReactiveRequest* request = [[HttpOrderReactiveRequest alloc] initWithOid:orderDetailDTO.id];
                            [request request]
                            .then(^(id responseObj){
                                if (request.response.ok) {
                                    [self.dataSource removeObject:orderDetailDTO];
                                    [self.tableView reloadData];
                                    [self showAlertViewWithMessage:@"激活成功"];
                                }
                                else {
                                    [self showAlertViewWithMessage:request.response.errorMsg];
                                }
                            })
                            .catch(^(NSError* error){
                                [self showAlertViewWithMessage:error.localizedDescription];
                            });
                        }
                     andCancelCallback:^(id x){
                         
                     }];
    }
    else {
        
        @weakify(self);
        [self showAlertViewWithMessage:[NSString stringWithFormat:@"确认要撤销订单: %ld 吗?", orderDetailDTO.id]
                        withOKCallback:^(id x){
                            @strongify(self);
                            HttpOrderCancelRequest* request = [[HttpOrderCancelRequest alloc] initWithOderId:orderDetailDTO.id];
                            [request request]
                            .then(^(id responseObj){
                                NSLog(@"%@", responseObj);
                                if (request.response.ok) {
                                    [self.dataSource removeObject:orderDetailDTO];
                                    [self.tableView reloadData];
                                    [self showAlertViewWithMessage:@"撤销成功"];
                                }
                                else {
                                    [self showAlertViewWithMessage:request.response.errorMsg];
                                }
                            })
                            .catch(^(NSError* error){
                                [self showAlertViewWithMessage:error.localizedDescription];
                            })
                            .finally(^(){
                            });
                        }
                     andCancelCallback:nil];
    }
    
    
}


#pragma  -- mark OrderSendVC delegate
-(void)sendSuccessWithOrderDetailDtos:(NSArray *)orderDetailDtos
{
    [self.dataSource removeObjectsInArray:orderDetailDtos];
}



-(void)dealloc
{
    NSLog(@"dealloc %@", [self class]);
}

@end
