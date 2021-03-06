//
//  CommonOrderListView.h
//  CrazeMM
//
//  Created by saix on 16/5/8.
//  Copyright © 2016年 189. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SegmentedCell.h"
#import "CommonBottomView.h"
#import "CustomSegment.h"
#import "BEMCheckBox.h"
#import "CommonListCell.h"
#import "HttpListQuery.h"
//@protocol CommonOrderListViewControllerProtocol <NSObject>
//
//
//@end



@interface CommonOrderListViewController : UIViewController<CustomSegmentDelegate, UITableViewDataSource, UITableViewDelegate, BEMCheckBoxDelegate, CommonListCellDelegate>
{
    @protected
    SegmentedCell* _segmentCell;
    CommonBottomView* _bottomView;
}

@property (nonatomic, strong) SegmentedCell* segmentCell;
@property (nonatomic, copy) NSArray* segmentTitles;
@property (nonatomic, readonly) NSInteger selectedSegmentIndex;
@property (nonatomic, strong) CommonBottomView* bottomView;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic) CGFloat contentHeightOffset;
@property (nonatomic, strong) NSMutableArray* dataSource;
@property (nonatomic, readonly) NSArray* selectedData;
@property (nonatomic, readonly) NSArray* unSelectedData;

@property (nonatomic) NSInteger totalRow;
@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) NSInteger totalPage;
@property (nonatomic) NSInteger pageSize;
@property (nonatomic, strong) HttpListQueryRequest* listQueryRequest;
@property (nonatomic) BOOL usingDefaultCell;
@property (nonatomic) BOOL autoRefresh;

-(UITableViewCell*)configCellByTableView:(UITableView*)tableView andIndexPath:(NSIndexPath*)indexPath;
-(HttpListQueryRequest*)makeListQueryRequest;
-(AnyPromise*)requestDataSource;
-(void)resetDataSource;

// method for bottomView
@property (nonatomic) NSString* bottomViewButtonTitle;
@property (nonatomic) NSString* bottomViewAddtionalButtonTitle;

//-(void)setActionForBottomViewButtonWithTarget:(id)target andAction:(SEL)action;
//-(void)setActionForBottomViewAddtonalButtonWithTarget:(id)target andAction:(SEL)action;

-(void)bottomViewButtonClicked:(UIButton*)button;
-(void)bottomViewAddtionalButtonClicked:(UIButton*)button;
-(void)updateBottomView;


@end
