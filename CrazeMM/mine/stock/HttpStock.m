//
//  HttpStock.m
//  CrazeMM
//
//  Created by Mao Mao on 16/5/30.
//  Copyright © 2016年 189. All rights reserved.
//

#import "HttpStock.h"

@implementation StockSellInfo

@end

@implementation HttpDepotQueryRequest


-(NSString*)url
{
    return COMB_URL(@"/rest/depot");
}

-(NSString*)method
{
    return @"GET";
}

-(Class)responseClass
{
    return [HttpDepotQueryResponse class];
}

@end

@implementation HttpDepotQueryResponse

-(void)parserResponse
{
    NSArray* depots = self.all[@"depot"];
    self.depotDtos = [[NSMutableArray alloc] init];
    
    for (NSDictionary* depot in depots) {
        NSLog(@"%@", depot);
        DepotDTO* dto = [[DepotDTO alloc] initWith:depot];
        [self.depotDtos addObject:dto];
    }
}

@end

@implementation HttpStockSellRequest

-(instancetype)initWithStocks:(StockSellInfo*)stocks
{
    self = [super init];
    if (self) {
        self.sellId = stocks.sellId;
        self.params = [@{
                         @"price" : @(stocks.price),
                         @"sale" : @(stocks.sale),
                         @"num" : @(stocks.num),
                         @"version" : @(stocks.version)
                         } mutableCopy];
    }
    return self;
}


-(NSString*)url
{
    NSString* url = [NSString stringWithFormat:@"/rest/stock/sell/%ld", self.sellId];
    return COMB_URL(url);
}

-(NSString*)method
{
    return @"POST";
}
@end


@implementation HttpStockDetailRequest

-(instancetype) initWithId:(NSInteger)stockId
{
    self = [super init];
    if (self) {
        self.stockId = stockId;
        }
    return self;
}

-(NSString*)url
{
    NSString* url = [NSString stringWithFormat:@"/rest/stock/%ld", self.stockId];
    return COMB_URL(url);
}

-(NSString*)method
{
    return @"GET";
}

-(Class)responseClass
{
    return [HttpStockDetailResponse class];
}

@end

@implementation HttpStockDetailResponse

-(void)parserResponse
{
    
    NSDictionary* stock = self.all[@"stock"];
        NSLog(@"%@", stock);
        self.stockDto = [[StockDetailDTO alloc] initWith:stock];
    
}

@end
