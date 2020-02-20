/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVKeychain.h"
#import "A0SimpleKeychain.h"

@implementation CDVKeychain

- (void) getAll:(CDVInvokedUrlCommand*)command {
  [self.commandDelegate runInBackground:^{
    NSArray* arguments = command.arguments;
    CDVPluginResult* pluginResult = nil;

    if([arguments count]<2 || [arguments count]>3) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
      messageAsString:@"incorrect number of arguments for getByUrlWithTouchID"];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      return;
    }

    NSString *touchIDMessage = [arguments objectAtIndex:0];
    Boolean icloud = [[arguments objectAtIndex:1] boolValue];
      
    NSString *message = NSLocalizedString(@"Please Authenticate", nil);
       if(![touchIDMessage isEqual:[NSNull null]]) {
         message = NSLocalizedString(touchIDMessage, @"Prompt TouchID message");
       }
    
    A0SimpleKeychain *keychain = [A0SimpleKeychain keychain];

    keychain.useAccessControl = YES;
    keychain.defaultAccessiblity = A0SimpleKeychainItemAccessibleWhenPasscodeSetThisDeviceOnly;
    keychain.icloudSync = icloud;
    NSArray *values;
    if (![[arguments objectAtIndex:2] isKindOfClass:[NSNull class]]) {
        NSString *url = [arguments objectAtIndex:2];
        values = [keychain arrayForServer:url message:message];
    }else{
        values = [keychain arrayOfAll:message];
    }
      NSString * valuesString = [self arrayToString:values];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:valuesString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}


-(NSString *) arrayToString:(NSArray *)array{
    NSString * finalString = @"[";
    Boolean first = true;
    for (NSDictionary * item in array) {
        NSString *dictionaryString =[self dictionaryToString:item];
        if (![dictionaryString isEqualToString:@""]) {
            if (first) {
                first = false;
                finalString = [finalString stringByAppendingString:dictionaryString];
            }else{
                finalString = [finalString stringByAppendingString:@","];
                finalString = [finalString stringByAppendingString:dictionaryString];
            }
        }
    }
    finalString = [finalString stringByAppendingString:@"]" ];
    return finalString;
}

-(NSString *) dictionaryToString:(NSDictionary *)dic{
    NSString * finalString = @"{\"Key\":\"";
    Boolean first = true;
    for (NSString * key in @[@"acct",@"v_Data"]) {
        if (first) {
            first = false;
            if ([[dic valueForKey:key] isKindOfClass:[NSData class]]) {
                if ([[[NSString alloc] initWithData:[dic valueForKey:key] encoding:NSUTF8StringEncoding] isEqualToString:@"_pfo"]) {
                    return @"";
                }
            }else{
                if ([[dic valueForKey:key] isEqualToString:@"_pfo"]) {
                    return @"";
                }
            }
            
        }else{
            finalString = [finalString stringByAppendingString:@",\"Value\":\""];
        }
        if ([[dic valueForKey:key] isKindOfClass:[NSData class]]) {
            finalString = [finalString stringByAppendingString:[[[NSString alloc] initWithData:[dic valueForKey:key] encoding:NSUTF8StringEncoding] stringByAppendingString:@"\""]];
        }else{
            finalString = [finalString stringByAppendingString:[[dic valueForKey:key] stringByAppendingString:@"\""]];
        }
    }
    finalString = [finalString stringByAppendingString:@"}"];
    return finalString;
}

- (void) get:(CDVInvokedUrlCommand*)command {
  [self.commandDelegate runInBackground:^{
    NSArray* arguments = command.arguments;
    CDVPluginResult* pluginResult = nil;

    if([arguments count] < 3 || [arguments count] > 4) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
      messageAsString:@"incorrect number of arguments for getWithTouchID"];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      return;
    }

    NSString *key = [arguments objectAtIndex:0];
    NSString *touchIDMessage = [arguments objectAtIndex:1];
    Boolean icloud = [[arguments objectAtIndex:2] boolValue];

    NSString *message = NSLocalizedString(@"Please Authenticate", nil);
    if(![touchIDMessage isEqual:[NSNull null]]) {
      message = NSLocalizedString(touchIDMessage, @"Prompt TouchID message");
    }

    A0SimpleKeychain *keychain = [A0SimpleKeychain keychain];

    keychain.useAccessControl = YES;
    keychain.defaultAccessiblity = A0SimpleKeychainItemAccessibleWhenPasscodeSetThisDeviceOnly;
    keychain.icloudSync = icloud;
    NSString *value;
    if (![[arguments objectAtIndex:3] isKindOfClass:[NSNull class]]) {
        NSString * url = [arguments objectAtIndex:3];
        value = [keychain stringForKey:key withUrl:url promptMessage:message];
    }else{
        value = [keychain stringForKey:key withUrl:nil promptMessage:message];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

- (void) set:(CDVInvokedUrlCommand*)command {
  [self.commandDelegate runInBackground:^{
    NSArray* arguments = command.arguments;
    CDVPluginResult* pluginResult = nil;

    if([arguments count] < 4 || [arguments count] > 5) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
      messageAsString:@"incorrect number of arguments for setWithTouchID"];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      return;
    }

    A0SimpleKeychain *keychain = [A0SimpleKeychain keychain];

    NSString* key = [arguments objectAtIndex:0];
    NSString* value = [arguments objectAtIndex:1];
    BOOL useTouchID = [[arguments objectAtIndex:2] boolValue];
    Boolean icloud = [[arguments objectAtIndex:3] boolValue];
    keychain.icloudSync = icloud;
    if(useTouchID) {
      keychain.useAccessControl = YES;
      keychain.defaultAccessiblity = A0SimpleKeychainItemAccessibleWhenPasscodeSetThisDeviceOnly;
    }
  
    if(![[arguments objectAtIndex:4] isKindOfClass:[NSNull class]]){
      NSString* url = [arguments objectAtIndex:4];
      [keychain setString:value forKey:key withUrl:url];
    }else{
      [keychain setString:value forKey:key withUrl:nil];
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

- (void) remove:(CDVInvokedUrlCommand*)command {
  [self.commandDelegate runInBackground:^{
    NSArray* arguments = command.arguments;
    CDVPluginResult* pluginResult = nil;

    if([arguments count] < 1 || [arguments count]>2) {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
      messageAsString:@"incorrect number of arguments for remove"];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      return;
    }

    NSString *key = [arguments objectAtIndex:0];

    A0SimpleKeychain *keychain = [A0SimpleKeychain keychain];
    if ([keychain hasValueForKey:key]) {
        [keychain deleteEntryForGenericKey:key];
    }
    if (![[arguments objectAtIndex:1] isKindOfClass:[NSNull class]]) {
        NSString *url = [arguments objectAtIndex:1];
        if([keychain hasValueForKeyUrl:key withUrl:url]){
            [keychain deleteEntryForInternetKeyUrlPair:key withUrl:url];
        }
    }
    

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }];
}

@end
