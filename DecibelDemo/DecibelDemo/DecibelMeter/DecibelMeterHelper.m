//
//  DecibelMeterHelper.m
//  DecibelDemo
//
//  Created by 0o on 2017/12/14.
//  Copyright © 2017年 Benight. All rights reserved.
//

#import "DecibelMeterHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

//临时音频存放的路径
#define VoiceFileTempSavePath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"VoiceTempFile.mp4"]

@interface DecibelMeterHelper()

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *decibelTimer;
@property (nonatomic, assign) float interval;

@end

@implementation DecibelMeterHelper
- (id) init {
    
    self = [super init];
    
    self.interval = 0.1;
    
    return self;
}

- (void) dealloc {
    
    [self.decibelTimer invalidate];
    self.decibelTimer = nil;
    
    if(self.recorder) {
        [self.recorder stop];
        self.recorder = nil;
    }
}

//麦克权限申请
- (void)microphonePermissionRequestWithIsSaveVoice:(BOOL)IsSaveVoice {

    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {
        //第一次询问用户是否进行授权
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                //授权成功
                [self configAVAudioRecorderWithIsSaveVoice:IsSaveVoice];
            } else {
                //授权失败
                [self showSetAlertView];
            }
        }];
    } else if(videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) {
        // 未授权
        [self showSetAlertView];
    } else{
        // 已授权
        [self configAVAudioRecorderWithIsSaveVoice:IsSaveVoice];
    }

}
- (void) startMeasuring {
    
    [self startMeasuringWithIsSaveVoice:NO];
}

- (void) startMeasuringWithIsSaveVoice:(BOOL)IsSaveVoice {
    
    
    [self microphonePermissionRequestWithIsSaveVoice:IsSaveVoice];
}

- (void)configAVAudioRecorderWithIsSaveVoice:(BOOL)IsSaveVoice {
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:NULL];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    if(!self.recorder) {
        
        NSDictionary *recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                                          [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                          [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                          [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                          [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey, nil];
        
        NSError* error = nil;
        
        //把音频的输入改为下面（PS：iPhone是有三个麦克风的，这个方法是把音频输入改为充电旁边的那个麦克风）
//        [self audioSessionInputInfo];
        for (AVAudioSessionPortDescription *portDesc in [[AVAudioSession sharedInstance] availableInputs ]) {
            [portDesc.dataSources enumerateObjectsUsingBlock:^(AVAudioSessionDataSourceDescription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.orientation isEqualToString:@"Bottom"]) {
                    [portDesc setPreferredDataSource:obj error:nil];
                }
            }];
            
        }
        NSURL *url = nil;
        if (IsSaveVoice) {
            //需要保存的地址
            NSString *tempDir = VoiceFileTempSavePath;
            url = [NSURL fileURLWithPath:tempDir];
            
        }else {
            //不需要保存录音文件
            url = [NSURL fileURLWithPath:@"/dev/null"];
        }
        
        self.recorder = [[AVAudioRecorder alloc] initWithURL:url
                                                    settings:recorderSettings
                                                       error:&error];
        if (self.recorder) {
            [self.recorder prepareToRecord];
            self.recorder.meteringEnabled = YES;
            [self.recorder record];
            [self.decibelTimer invalidate];
            self.decibelTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(recordDecibelLevel:) userInfo:nil repeats:YES];
        }
    }
    
}


- (void) stopMeasuring {
    
    [self.decibelTimer invalidate];
    self.decibelTimer = nil;
    
    if(self.recorder) {
        [self.recorder stop];
        self.recorder = nil;
    }
}

- (void)recordDecibelLevel:(NSTimer*)timer {
    
    [self.recorder updateMeters];
//    [self test1];
    [self test2];
//    [self test3];
}

- (void)test1 {
    float   level;
    float   minDecibels = -60.0f;
    float   decibels    = [self.recorder averagePowerForChannel:0];
    if (decibels < minDecibels)    {
        level = 0.0f;
    }    else if (decibels >= 0.0f)    {
        level = 1.0f;
    }    else    {
        float   root = 2.0f;
        float   minAmp = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp = powf(10.0f, 0.05f * decibels);
        float   adjAmp = (amp - minAmp) * inverseAmpRange;
        level = powf(adjAmp, 1.0f / root);
    }
    double dB = level*85;
    NSLog(@"dB = %f", dB);
    
    if (self.decibelMeterBlock) {
        self.decibelMeterBlock (dB);
    }

}

- (void)test2 {

    float power = [self.recorder averagePowerForChannel:0];

    CGFloat progress = (1.0 / 160.0) * (power + 160.0);

    power = power + 160  - 40;

    double dB = 0;
    if (power < 0.f) {
        dB = 0;
    } else if (power < 40.f) {
        dB = (int)(power * 0.875);
    } else if (power < 100.f) {
        dB = (int)(power - 15);
    } else if (power < 110.f) {
        dB = (int)(power * 2.5 - 165);
    } else {
        dB = 110;
    }


    NSLog(@"progress = %f, dB = %f", progress, dB);
    if (self.decibelMeterBlock) {
        self.decibelMeterBlock (dB);
    }


}

- (void)test3 {

    CGFloat agv = pow(10, (0.05 * [self.recorder averagePowerForChannel:0]));
//    CGFloat agv = pow (10, [self.recorder averagePowerForChannel:0] / 120);
    double dB = agv*100 ;

    NSLog(@"%f",dB);
    if (self.decibelMeterBlock) {
        self.decibelMeterBlock (dB);
    }
}
#pragma mark - other
//提示用户进行麦克风使用授权
- (void)showSetAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"麦克风权限未开启" message:@"麦克风权限未开启，请进入系统【设置】>【隐私】>【麦克风】中打开开关,开启麦克风功能" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //跳入当前App设置界面
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:setAction];
    
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    [window.rootViewController presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - 在网上找了一些其他转化分贝的方法


#pragma mark - 下面的代码是可以看输入源的一些信息--test
- (void)audioSessionInputInfo {

    NSArray* input = [[AVAudioSession sharedInstance] currentRoute].inputs;
//        NSArray* output = [[AVAudioSession sharedInstance] currentRoute].outputs;
    NSLog(@"current intput:%@",input);
    NSArray* availableInputs = [[AVAudioSession sharedInstance] availableInputs];
    NSLog(@"available inputs:%@",availableInputs);
    
    
    for (AVAudioSessionPortDescription *portDesc in [[AVAudioSession sharedInstance] availableInputs ]) {
        [portDesc.dataSources enumerateObjectsUsingBlock:^(AVAudioSessionDataSourceDescription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.orientation isEqualToString:@"Bottom"]) {
                [portDesc setPreferredDataSource:obj error:nil];
            }
        }];
        NSLog(@"-----");
        NSLog(@"portDesc UID --%@", portDesc.UID);
        NSLog(@"portDesc portName --%@", portDesc.portName);
        NSLog(@"portDesc portType --%@", portDesc.portType);
        NSLog(@"portDesc channels --%@", portDesc.channels);
        NSLog(@"portDesc selectedDataSource --%@", portDesc.selectedDataSource);
        NSLog(@"portDesc selectedDataSource dataSourceID--%@", portDesc.selectedDataSource.dataSourceID);
        NSLog(@"portDesc selectedDataSource dataSourceName--%@", portDesc.selectedDataSource.dataSourceName);
        NSLog(@"portDesc selectedDataSource location--%@", portDesc.selectedDataSource.location);
        NSLog(@"portDesc selectedDataSource orientation--%@", portDesc.selectedDataSource.orientation);
        NSLog(@"portDesc selectedDataSource supportedPolarPatterns--%@", portDesc.selectedDataSource.supportedPolarPatterns);
        NSLog(@"portDesc selectedDataSource selectedPolarPattern--%@", portDesc.selectedDataSource.selectedPolarPattern);
        NSLog(@"portDesc selectedDataSource preferredPolarPattern--%@", portDesc.selectedDataSource.preferredPolarPattern);
        
    }
//    [[[UIAlertView alloc]initWithTitle:[self replaceUnicode:[NSString stringWithFormat:@"%@",input]] message:[self replaceUnicode:[NSString stringWithFormat:@"%@",availableInputs]] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil]show];

}
- (NSString *)replaceUnicode:(NSString *)unicodeStr {
    
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListFromData:tempData
                                                           mutabilityOption:NSPropertyListImmutable
                                                                     format:NULL
                                                           errorDescription:NULL];
    
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}


@end
