//
//  FilterTagsCell.m
//  CrazeMM
//
//  Created by saix on 16/6/26.
//  Copyright © 2016年 189. All rights reserved.
//

#import "FilterTagsCell.h"

@interface FilterTagsCell ()

@property (nonatomic, strong) NSMutableArray* filterTagLabels;
@end


@implementation FilterTagsCell

//-(instancetype)init

-(void)setFilterTags:(NSArray *)filterTags
{
    _filterTags = filterTags;
    for (UIView* label in self.filterTagLabels) {
        [label removeFromSuperview];
    }
    
    [self.filterTagLabels removeAllObjects];
    self.filterTagLabels = [[NSMutableArray alloc] init];
    for(NSString* filterTag in filterTags){
        FilterTagLabel* label = [[FilterTagLabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.filterTag = filterTag;
        [self.contentView addSubview:label];
        [self.filterTagLabels addObject:label];
        label.delegate = self.delegate;
    }
    
    
    CGRect contentFrame = [UIScreen mainScreen].bounds;
    NSInteger index;
    CGFloat y = 0;
    CGFloat x = 8.f;
    CGFloat width = ceil((contentFrame.size.width-4*2-8.f*2-50.f)/3);
    CGFloat height = 28.f;
    for (index=0; index<self.filterTags.count; index+=3) {
        x = 8.f;
        for (NSInteger step=0; step<3; step++) {
            
            if (index+step>=self.filterTags.count) {
                break;
            }
            FilterTagLabel* label = self.filterTagLabels[index+step];
            label.frame = CGRectMake(x, y, width, height);
            x += width+4.f;
        }
        y += height+8.f;
    }
    
    self.height = y;
    
}

-(void)layoutSubviews
{
    [super layoutSubviews];
}

-(void)reset
{
    for (FilterTagLabel* label in self.filterTagLabels) {
        label.isSelected = NO;
    }
}

-(NSArray*)selectedTags
{
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    for (FilterTagLabel* label in self.filterTagLabels) {
        if (label.isSelected) {
            [arr addObject:label.text];
        }
    }
    
    return arr;
}

@end
