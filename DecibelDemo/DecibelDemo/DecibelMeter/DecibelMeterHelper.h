//
//  DecibelMeterHelper.h
//  DecibelDemo
//
//  Created by 0o on 2017/12/14.
//  Copyright © 2017年 Benight. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DecibelMeterBlock)(double dbSPL);

@interface DecibelMeterHelper : NSObject

@property (nonatomic, copy) DecibelMeterBlock decibelMeterBlock;

/** 开始，是否保存文件*/
- (void)startMeasuringWithIsSaveVoice:(BOOL)IsSaveVoice;

/** 开始，默认保存文件*/
- (void)startMeasuring;

/** 停止*/
- (void)stopMeasuring;

@end
