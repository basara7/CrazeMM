//
//  OnlinePayViewController.h
//  CrazeMM
//
//  Created by saix on 16/5/15.
//  Copyright © 2016年 189. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PayInfoDTO.h"

@interface OnlinePayViewController : UIViewController<UIWebViewDelegate>

-(instancetype)initWithPayInfoDto:(PayInfoDTO*)payInfoDto;


@end