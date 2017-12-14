//
//  ViewController.m
//  DecibelDemo
//
//  Created by 0o on 2017/12/14.
//  Copyright © 2017年 Benight. All rights reserved.
//

#import "ViewController.h"
#import "DecibelMeterHelper.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *dbLabel;
- (IBAction)processStartAction:(id)sender;
- (IBAction)processStopAction:(id)sender;

@property (nonatomic, strong) DecibelMeterHelper           *dbHelper;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dbHelper = [[DecibelMeterHelper alloc]init];
    
    __weak typeof(self) weakSelf = self;
    self.dbHelper.decibelMeterBlock = ^(double dbSPL){
        
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.dbLabel.text = [NSString stringWithFormat:@"%.2lf",dbSPL];
        });

    };
    
}

- (IBAction)processStartAction:(id)sender {
    [self.dbHelper startMeasuringWithIsSaveVoice:NO];

}

- (IBAction)processStopAction:(id)sender {
    [self.dbHelper stopMeasuring];
}
@end
