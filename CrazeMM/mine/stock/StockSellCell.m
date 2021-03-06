//
//  StockSellCell.m
//  CrazeMM
//
//  Created by Mao Mao on 16/6/1.
//  Copyright © 2016年 189. All rights reserved.
//

#import "StockSellCell.h"

@implementation StockSellCell

- (void)awakeFromNib {
    // Initialization code
    self.unitPriceField.layer.borderColor = [UIColor light_Gray_Color].CGColor;
    self.unitPriceField.layer.borderWidth = .5f;
    self.unitPriceField.keyboardType = UIKeyboardTypeDecimalPad;
    
    self.totalNumField.layer.borderColor = [UIColor light_Gray_Color].CGColor;
    self.totalNumField.layer.borderWidth = .5f;
    self.totalNumField.keyboardType = UIKeyboardTypeNumberPad;
    
    self.seperateNumField.layer.borderColor = [UIColor light_Gray_Color].CGColor;
    self.seperateNumField.layer.borderWidth = .5f;
    self.seperateNumField.text = @"1";
    self.seperateNumField.keyboardType = UIKeyboardTypeNumberPad;
    self.totalNumField.delegate = self;
    self.unitPriceField.delegate = self;
    self.seperateNumField.delegate = self;
    
    //totalNumField
    @weakify(self);
    self.addButton1.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
        
        @strongify(self);
        NSUInteger totalNumber = self.totalCountNum;
        NSUInteger currentNumber = [self.totalNumField.text integerValue];
        
        if (currentNumber  < totalNumber) {
            self.totalNumField.text = [NSString stringWithFormat:@"%lu", currentNumber+1];
        }
        
        return [RACSignal empty];
    }];
    
    self.subButton1.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
        
        @strongify(self);
        NSUInteger currentNumber = [self.totalNumField.text integerValue];
        
        if (currentNumber  > 0) {
            self.totalNumField.text = [NSString stringWithFormat:@"%lu", currentNumber-1];
        }
        
        return [RACSignal empty];
    }];
    
    //seperateNumField
    self.addButton2.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
        
        @strongify(self);
        NSUInteger totalNumber = [self.totalNumField.text integerValue];
        NSUInteger currentNumber = [self.seperateNumField.text integerValue];
        
        if (currentNumber  < totalNumber) {
            self.seperateNumField.text = [NSString stringWithFormat:@"%lu", currentNumber+1];
        }
        
        return [RACSignal empty];
    }];
    
    self.subButton2.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal* (id x){
        
        @strongify(self);
        NSUInteger currentNumber = [self.seperateNumField.text integerValue];
        currentNumber = currentNumber-1;
        if (currentNumber) {
            self.seperateNumField.text = [NSString stringWithFormat:@"%lu", currentNumber];
        }
        
        return [RACSignal empty];
    }];
    
    
    RACSignal* totalPriceSignal =
        [RACSignal combineLatest:@[self.seperateNumField.rac_textSignal,
                                   RACObserve(self, seperateNumField.text),
                                   self.totalNumField.rac_textSignal,
                                   RACObserve(self, totalNumField.text),
                                   self.unitPriceField.rac_textSignal,
                                   RACObserve(self, unitPriceField.text)]];
    [totalPriceSignal subscribeNext:^(id x){
        @strongify(self);
        [self fomartTotalPriceLabel];
        if ([self.delegate respondsToSelector:@selector(refreshTotalPriceLabel)]) {
            [self.delegate refreshTotalPriceLabel];
        }
        [self updateDto];

    }];
    
    
    self.checkBox.onCheckColor = [UIColor whiteColor];
    self.checkBox.onTintColor = [UIColor redColor];
    self.checkBox.onFillColor = [UIColor redColor];
    self.checkBox.boxType = BEMBoxTypeCircle;
    self.checkBox.animationDuration = 0.f;
    self.checkBox.on = NO;
    self.checkBox.delegate = self;
    
    [self fomartTotalPriceLabel];
    
    
    [RACObserve(self.checkBox, hidden) subscribeNext:^(NSNumber* x){
        @strongify(self);
        if ([x boolValue]) {
            self.titleLabelLeadingConstraint.constant = 0;
        }
        else {
            self.titleLabelLeadingConstraint.constant = 26;
        }
        [self updateConstraints];
    }];
    

}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString* finnalString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (textField == self.totalNumField)
    {
        if (finnalString.length == 0)
        {
            textField.text = @"";
        }
        else if ([finnalString integerValue] > self.totalCountNum)
        {
             textField.text = [NSString stringWithFormat:@"%ld", self.totalCountNum];
        }
        else if([finnalString integerValue] <= 0)
        {
            textField.text = @"0";
        }
        else {
            textField.text = finnalString;
        }
//        [self fomartTotalPriceLabel];
//        if ([self.delegate respondsToSelector:@selector(refreshTotalPriceLabel)]) {
//            [self.delegate refreshTotalPriceLabel];
//        }

    }
    else if (textField == self.unitPriceField)
    {
        if (finnalString.length == 0)
        {
            textField.text = @"";
        }
        else if ([finnalString integerValue] <= 0)
        {
            textField.text = @"1";
        }
        else {
            textField.text = finnalString;
        }
//        [self fomartTotalPriceLabel];
//        if ([self.delegate respondsToSelector:@selector(refreshTotalPriceLabel)]) {
//            [self.delegate refreshTotalPriceLabel];
//        }

    }
    else if (textField == self.seperateNumField)
    {
        if (finnalString.length == 0)
        {
            textField.text = @"";
        }
        else if ([finnalString integerValue] > [self.totalNumField.text integerValue])
        {
            textField.text = self.totalNumField.text;
        }
        else if ([finnalString integerValue] <= 0)
        {
            textField.text = @"1";
        }
        else {
            textField.text = finnalString;
        }
    }
    [self updateDto];

    
    return NO;
}


-(void)fomartTotalPriceLabel
{
    self.totalPriceLabel.backgroundColor = [UIColor UIColorFromRGB:0xf7f7f7];
    self.backgroundLabel.backgroundColor = [UIColor UIColorFromRGB:0xf7f7f7];
    
    self.totalPriceLabel.text = @"";
    self.totalPriceLabel.textAlignment = kCTTextAlignmentRight;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]initWithString:@"净赚: "];
    [attributedText m80_setFont:[UIFont systemFontOfSize:12.f]];
    [attributedText m80_setTextColor:[UIColor grayColor]];
    [self.totalPriceLabel appendAttributedText:attributedText];
    
    attributedText = [[NSMutableAttributedString alloc]initWithString:@"￥"];
    [attributedText m80_setFont:[UIFont systemFontOfSize:12.f]];
    [attributedText m80_setTextColor:[UIColor redColor]];
    [self.totalPriceLabel appendAttributedText:attributedText];
    
    //calculate earning
     self.earning = [self.totalNumField.text integerValue]*([self.unitPriceField.text integerValue] - self.stockDto.inprice );
//    self.earning = self.earning>=0?self.earning:0;
   NSString* strEarning = [[NSString alloc] initWithFormat:@"%ld", self.earning];
    self.stockDto.earning = self.earning;
    if (self.stockDetailDto) {
        self.stockDetailDto.earning = self.earning;
    }
    
    attributedText = [[NSMutableAttributedString alloc]initWithString:strEarning];
    [attributedText m80_setFont:[UIFont boldSystemFontOfSize:16.f]];
    [attributedText m80_setTextColor:[UIColor redColor]];
    [self.totalPriceLabel appendAttributedText:attributedText];
    
    attributedText = [[NSMutableAttributedString alloc]initWithString:@".00"];
    [attributedText m80_setFont:[UIFont systemFontOfSize:12.f]];
    [attributedText m80_setTextColor:[UIColor redColor]];
    [self.totalPriceLabel appendAttributedText:attributedText];
    [self.totalPriceLabel appendText:@""];
    self.totalPriceLabel.numberOfLines = 1;
    self.totalPriceLabel.offsetY = -4.f;
}

- (void)setStockDto:(MineStockDTO *)stockDto
{
    _stockDto = stockDto;
    self.totalCountNum = stockDto.presale;
    self.productTitleLabel.text = stockDto.goodName;
    self.orignalUnitPriceLabel.text = [NSString stringWithFormat:@"￥%lu", (NSInteger)stockDto.inprice];
    self.unitPriceField.text = [NSString stringWithFormat:@"%lu", (NSInteger)stockDto.inprice];
    self.totalNumField.text = [NSString stringWithFormat:@"%lu", stockDto.presale];
    self.checkBox.on = stockDto.selected;
    [self updateDto];

}

-(void)setStockDetailDto:(StockDetailDTO *)stockDetailDto
{
    _stockDetailDto = stockDetailDto;
    MineStockDTO* stockDto = [[MineStockDTO alloc] initWithStockDetailDTO:stockDetailDto];
    self.stockDto = stockDto;
}

-(void)didTapCheckBox:(BEMCheckBox *)checkBox
{
    self.stockDetailDto.selected = checkBox.on;
    self.stockDto.selected = checkBox.on;
    if ([self.delegate respondsToSelector:@selector(didTapCheckBox:)]) {
        [self.delegate didTapCheckBox:checkBox];
    }
}

- (void)updateDto
{
    self.stockDto.currentPrice = [self.unitPriceField.text integerValue];
    self.stockDto.currentSale = [self.totalNumField.text integerValue];
    self.stockDto.currentNum = [self.seperateNumField.text integerValue];
    
    if (self.stockDetailDto) {
        self.stockDetailDto.currentPrice = [self.unitPriceField.text integerValue];
        self.stockDetailDto.currentSale = [self.totalNumField.text integerValue];
        self.stockDetailDto.currentNum = [self.seperateNumField.text integerValue];
    }
}


+(CGFloat)cellHeight
{
    return 150.f;
}

-(void)dealloc
{
    NSLog(@"Dealloc %@", self.class);
}

@end
