//
//  ViewController.m
//  NFC-Reader-Objective-C
//
//  Created by Kevin Lu on 23/09/20.
//  Copyright © 2020 Trackit. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import "NSData+Conversion.h"

@import CoreNFC;

@interface ViewController ()<NFCNDEFReaderSessionDelegate, NFCTagReaderSessionDelegate>

@property (nonatomic, strong) NFCNDEFReaderSession *ndefSession;
@property (nonatomic, strong) NFCTagReaderSession *tagReaderSession;
@property (nonatomic, strong) NSMutableArray<NFCNDEFMessage *> *detectedMessages;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.detectedMessages = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view.
}

- (IBAction)startScanISO14443:(id)sender {
    [self.ndefSession invalidateSession];
    self.tagReaderSession = [[NFCTagReaderSession alloc] initWithPollingOption:NFCPollingISO14443 delegate:self queue:nil];
    self.tagReaderSession.alertMessage = @"Hold your iPhone near the item to learn more about it.";
    [self.tagReaderSession beginSession];
}

- (IBAction)stopScanISO14443:(id)sender {
    [self.tagReaderSession invalidateSession];
}

- (IBAction)startScanNdef:(id)sender {
    [self.tagReaderSession invalidateSession];
    self.ndefSession = [[NFCNDEFReaderSession alloc] initWithDelegate:self
                       queue:nil
    invalidateAfterFirstRead:false];
    self.ndefSession.alertMessage = @"Hold your iPhone near the item to learn more about it.";
    [self.ndefSession beginSession];
}

- (IBAction)stopScanNdef:(id)sender {
    [self.ndefSession invalidateSession];
}

#pragma mark - NFCTagReaderSessionDelegate Methods
- (void)tagReaderSession:(NFCTagReaderSession *)session didInvalidateWithError:(NSError *)error API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos) {
    
}

- (void)tagReaderSession:(NFCTagReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos) {
    
    NSLog(@"reader：%s===%@", __FUNCTION__, tags);
    if (tags.count > 1) {
        [session setAlertMessage:@"More than 1 tag is detected, please remove all tags and try again."];
        NSTimeInterval retryInterval = 500;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, retryInterval), ^{
            [session restartPolling];
        });
        [session restartPolling];
        return;
    }
    
    // Connect to the found tag and perform NDEF message reading
    id<NFCTag> tag = tags[0];
    [session connectToTag:tag completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            [session setAlertMessage:@"Unable to connect to tag."];
            [session invalidateSession];
            return;
        }
        id<NFCMiFareTag> miFareTag = tag.asNFCMiFareTag;
        NSData *serial = [miFareTag identifier];
        if (serial != nil) {
            NSString *tag1DataStr = [serial hexadecimalString];
            NSLog(@"reader：%s=== hexadecimal string =%@", __FUNCTION__, tag1DataStr);
            NSString *message = [NSString stringWithFormat:@"Successfully linked tag: %@", tag1DataStr];
            [session setAlertMessage:message];
            [session invalidateSession];
            return;
        }
        [session invalidateSession];
    }];
}


#pragma mark - NFCNDEFReaderSessionDelegate Methods
- (void)readerSession:(NFCNDEFReaderSession *)session didDetectNDEFs:(NSArray<NFCNDEFMessage *> *)messages {
    NSLog(@"reader：%s===%@", __FUNCTION__, messages);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.detectedMessages addObjectsFromArray:messages];
        NSLog(@"detectedMessages %@", self.detectedMessages);
    });
}

- (void)readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
}

- (void)readerSessionDidBecomeActive:(NFCNDEFReaderSession *)session  API_AVAILABLE(ios(11.0)){
    
}

- (void)readerSession:(NFCNDEFReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCNDEFTag>> *)tags API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos) {
    NSLog(@"reader：%s===%@", __FUNCTION__, tags);
    if (tags.count > 1) {
        [session setAlertMessage:@"More than 1 tag is detected, please remove all tags and try again."];
        NSTimeInterval retryInterval = 500;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, retryInterval), ^{
            [session restartPolling];
        });
        [session restartPolling];
        return;
    }
    
    // Connect to the found tag and perform NDEF message reading
    id<NFCNDEFTag> tag = tags[0];
    [session connectToTag:tag completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            [session setAlertMessage:@"Unable to connect to tag."];
            [session invalidateSession];
            return;
        }
        
        [tag queryNDEFStatusWithCompletionHandler:^(NFCNDEFStatus status, NSUInteger capacity, NSError * _Nullable error) {
            
            if (NFCNDEFStatusNotSupported == status) {
                [session setAlertMessage:@"Tag is not NDEF compliant"];
                [session invalidateSession];
            } else if (error != nil) {
                [session setAlertMessage:@"Unable to query NDEF status of tag"];
                [session invalidateSession];
            }
            [tag readNDEFWithCompletionHandler:^(NFCNDEFMessage * _Nullable message, NSError * _Nullable error) {
                NSString *statusMessage = @"";
                if (error != nil || message == nil) {
                    statusMessage = @"Fail to read NDEF from tag";
                } else {
                    statusMessage = @"Found 1 NDEF message";
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.detectedMessages addObject:message];
                        NSLog(@"detectedMessages %@", self.detectedMessages);
                    });
                }
                [session setAlertMessage:statusMessage];
                [session invalidateSession];
            }];
        }];
    }];
}

@end
