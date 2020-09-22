//
//  NSData+Conversion.h
//  NFC-Reader-Objective-C
//
//  Created by Kevin Lu on 23/09/20.
//  Copyright © 2020 Trackit. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString;

@end

NS_ASSUME_NONNULL_END
