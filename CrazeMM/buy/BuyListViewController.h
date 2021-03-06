//
//  BuyViewController.h
//  CrazeMM
//
//  Created by saix on 16/4/18.
//  Copyright © 2016年 189. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"

@protocol ProductSummaryViewControllerDelegate <NSObject>

-(void)refreshData;

@end

@interface BuyListViewController : UIViewController<iCarouselDataSource, iCarouselDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray* dataSource;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) NSInteger totalPage;
@property (nonatomic) BOOL requesting;
@property (nonatomic, weak) id<ProductSummaryViewControllerDelegate> delegate;
-(void)refreshData;
-(void)refreshDataNoHud;
//-(void)clearData;
//-(AnyPromise*)getProducts:(BOOL)needHud;
@end
