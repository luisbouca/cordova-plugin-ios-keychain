//  A0SimpleKeychain.h
//
// Copyright (c) 2014 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "A0SimpleKeychain.h"

@interface A0SimpleKeychain ()

@end

@implementation A0SimpleKeychain

- (instancetype)init {
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    return [self initWithService:service accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service {
    return [self initWithService:service accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    self = [super init];
    if (self) {
        _service = service;
        _accessGroup = accessGroup;
        _defaultAccessiblity = A0SimpleKeychainItemAccessibleAfterFirstUnlock;
        _useAccessControl = NO;
        _icloudSync = NO;
    }
    return self;
}

-(NSArray *) arrayOfAll:(NSString*)message{
    NSDictionary *query = [self queryFindAllGeneric:message];
    CFArrayRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    NSArray * items1, * items2;
    if (status == errSecSuccess || status == errSecItemNotFound) {
      items1 = [NSArray arrayWithArray:(__bridge NSArray *)result];
      CFBridgingRelease(result);
    }
    NSDictionary *query2 = [self queryFindAllInternet:message];
    CFArrayRef result2 = nil;
    OSStatus status2 = SecItemCopyMatching((__bridge CFDictionaryRef)query2, (CFTypeRef *)&result2);
    if (status2 == errSecSuccess || status2 == errSecItemNotFound) {
      items2 = [NSArray arrayWithArray:(__bridge NSArray *)result2];
      CFBridgingRelease(result2);
    }
    if (items1 != nil) {
        if (items2 != nil) {
            NSMutableSet *mergedArray = [NSMutableSet setWithArray:items1];
            [mergedArray unionSet:[NSSet setWithArray:items2]];
            return [mergedArray allObjects];
        }else{
            return items1;
        }
    }else{
        return items2;
    }
}

-(NSArray *) arrayForServer:(NSString *) url message:(NSString*)message{
    NSDictionary *query = [self queryFindAllInternetByUrl:url message:message];
    CFArrayRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecSuccess || status == errSecItemNotFound) {
      NSArray *items = [NSArray arrayWithArray:(__bridge NSArray *)result];
      CFBridgingRelease(result);
      return items;
    }
    return nil;
}

- (NSString *)stringForKey:(NSString *)key {
    return [self stringForKey:key withUrl:nil promptMessage:nil];
}

- (NSString *)stringForKeyUrl:(NSString *)key withUrl:(NSString *)url {
    return [self stringForKey:key withUrl:url promptMessage:nil];
}


- (NSData *)dataForKey:(NSString *)key withUrl:(NSString *)url {
    return [self dataForKey:key withUrl:url promptMessage:nil];
}


- (nullable NSString *)stringForUrl:(NSString *)url promptMessage:(NSString *)message{
    NSData *data = [self dataForUrl:url promptMessage:message];
    NSString *string = nil;
    if (data) {
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return string;
}

- (NSString *)stringForKey:(NSString *)key withUrl:(NSString *)url promptMessage:(NSString *)message {
    NSData *data = [self dataForKey:key withUrl:url promptMessage:message];
    NSString *string = nil;
    if (data) {
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return string;
}

- (NSData *)dataForKey:(NSString *)key withUrl:(NSString *) url promptMessage:(NSString *)message {
    return [self dataForKey:key withUrl:url promptMessage:message error:nil];
}

- (NSData *)dataForUrl:(NSString *) url promptMessage:(NSString *)message {
    return [self dataForUrl:url promptMessage:message error:nil];
}

- (NSData *)dataForUrl:(NSString *)url promptMessage:(NSString *)message error:(NSError**)err {
    if (!url) {
        return nil;
    }
    CFTypeRef data = nil;
    
    NSDictionary *query = [self queryFindByUrl:url message:message];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
    if (status != errSecSuccess) {
        if(err != nil) {
            *err = [NSError errorWithDomain:A0ErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey : [self stringForSecStatus:status]}];
        }
        return nil;
    }

    NSData *dataFound = [NSData dataWithData:(__bridge NSData *)data];
    if (data) {
        CFRelease(data);
    }

    return dataFound;
}

- (NSData *)dataForKey:(NSString *)key withUrl:(NSString *)url promptMessage:(NSString *)message error:(NSError**)err {
    if (!key) {
        return nil;
    }
    CFTypeRef data = nil;
    if (!url) {
        NSDictionary *queryGen = [self queryFetchOneGenericByKey:key message:message];
        OSStatus statusGen = SecItemCopyMatching((__bridge CFDictionaryRef)queryGen, &data);
        if (statusGen != errSecSuccess) {
            if(err != nil) {
                *err = [NSError errorWithDomain:A0ErrorDomain code:statusGen userInfo:@{NSLocalizedDescriptionKey : [self stringForSecStatus:statusGen]}];
                return nil;
            }else if(data == nil){
                NSDictionary *queryInt = [self queryFetchOneInternetByKey:key message:message];
                OSStatus statusInt = SecItemCopyMatching((__bridge CFDictionaryRef)queryInt, &data);
                if (statusInt != errSecSuccess) {
                    if(err != nil) {
                        *err = [NSError errorWithDomain:A0ErrorDomain code:statusInt userInfo:@{NSLocalizedDescriptionKey : [self stringForSecStatus:statusInt]}];
                    }
                    return nil;
                }
            }
        }
    }else{
        NSDictionary *query = [self queryFetchOneByUrlandKey:url withkey:key message:message];
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
        if (status != errSecSuccess) {
            if(err != nil) {
                *err = [NSError errorWithDomain:A0ErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey : [self stringForSecStatus:status]}];
            }
            return nil;
        }
    }

    NSData *dataFound = [NSData dataWithData:(__bridge NSData *)data];
    if (data) {
        CFRelease(data);
    }

    return dataFound;
}

- (BOOL)hasValueForUrl:(NSString *)url {
    if (!url) {
        return NO;
    }
    NSDictionary *query = [self queryFindByUrl:url message:nil];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    return status == errSecSuccess;
}

- (BOOL)hasValueForKeyUrl:(NSString *)key withUrl:(NSString *)url {
    if (!url && !key) {
        return NO;
    }
    NSDictionary *query = [self queryFindByUrlandKey:url withkey:key message:nil];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    return status == errSecSuccess;
}

- (BOOL)hasValueForKey:(NSString *)key {
    if (!key) {
        return NO;
    }
    NSDictionary *queryGen = [self queryFindGenericByKey:key message:nil];
    NSDictionary *queryInt = [self queryFindInternetByKey:key message:nil];
    OSStatus statusGen = SecItemCopyMatching((__bridge CFDictionaryRef)queryGen, NULL);
    OSStatus statusInt = SecItemCopyMatching((__bridge CFDictionaryRef)queryInt, NULL);
    return statusGen == errSecSuccess || statusInt == errSecSuccess;
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key withUrl:(NSString *)url {
    return [self setString:string forKey:key withUrl:url promptMessage:nil];
}

- (BOOL)setData:(NSData *)data forKey:(NSString *)key {
    //return [self setData:data forKey:key promptMessage:nil];
    return false;
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key withUrl:(NSString *)url promptMessage:(NSString *)message {
    NSData *data = key ? [string dataUsingEncoding:NSUTF8StringEncoding] : nil;
    return [self setData:data forKey:key withUrl:url promptMessage:message];
}


- (BOOL)setData:(NSData *)data forKey:(NSString *)key withUrl:(NSString *)url promptMessage:(NSString *)message {
    if (!key) {
        return NO;
    }
    if (!!url) {
        NSDictionary *query = [self queryFindByUrlandKey:url withkey:key message:message];

        // Touch ID case
        if (self.useAccessControl && self.defaultAccessiblity == A0SimpleKeychainItemAccessibleWhenPasscodeSetThisDeviceOnly) {
            // TouchId case. Doesn't support updating keychain items
            // see Known Issues: https://developer.apple.com/library/ios/releasenotes/General/RN-iOSSDK-8.0/
            // We need to delete old and add a new item. This can fail
            OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
            if (status == errSecSuccess || status == errSecItemNotFound) {
                NSDictionary *newQuery = [self queryNewInternetKey:key value:data url:url];
                OSStatus status = SecItemAdd((__bridge CFDictionaryRef)newQuery, NULL);
                return status == errSecSuccess;
            }
        }

        // Normal case
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        if (status == errSecSuccess) {
            if (data) {
                NSDictionary *updateQuery = [self queryUpdateValue:data message:message];
                status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateQuery);
                return status == errSecSuccess;
            } else {
                OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
                return status == errSecSuccess;
            }
        } else {
            NSDictionary *newQuery = [self queryNewInternetKey:key value:data url:url];
            OSStatus status = SecItemAdd((__bridge CFDictionaryRef)newQuery, NULL);
            return status == errSecSuccess;
        }
    }else{
        NSDictionary *query = [self queryFindGenericByKey:key message:message];

        // Touch ID case
        if (self.useAccessControl && self.defaultAccessiblity == A0SimpleKeychainItemAccessibleWhenPasscodeSetThisDeviceOnly) {
            // TouchId case. Doesn't support updating keychain items
            // see Known Issues: https://developer.apple.com/library/ios/releasenotes/General/RN-iOSSDK-8.0/
            // We need to delete old and add a new item. This can fail
            OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
            if (status == errSecSuccess || status == errSecItemNotFound) {
                NSDictionary *newQuery = [self queryNewGenericKey:key value:data];
                OSStatus status = SecItemAdd((__bridge CFDictionaryRef)newQuery, NULL);
                return status == errSecSuccess;
            }
        }

        // Normal case
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        if (status == errSecSuccess) {
            if (data) {
                NSDictionary *updateQuery = [self queryUpdateValue:data message:message];
                status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateQuery);
                return status == errSecSuccess;
            } else {
                OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
                return status == errSecSuccess;
            }
        } else {
            NSDictionary *newQuery = [self queryNewGenericKey:key value:data];
            OSStatus status = SecItemAdd((__bridge CFDictionaryRef)newQuery, NULL);
            return status == errSecSuccess;
        }
    }
}

- (BOOL)deleteEntryForGenericKey:(NSString *)key {
    if (!key) {
        return NO;
    }
    NSDictionary *deleteQuery = [self queryFindGenericByKey:key message:nil];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    return status == errSecSuccess;
}
- (BOOL)deleteEntryForInternetKeyUrlPair:(NSString *)key withUrl:(NSString *)url {
    if (!key && !url) {
        return NO;
    }
    NSDictionary *deleteQuery = [self queryFindByUrlandKey:key withkey:url message:nil];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    return status == errSecSuccess;
}


- (void)clearAllGeneric {
#if TARGET_OS_IPHONE
    NSDictionary *query = [self queryFindAllGeneric:nil];
  CFArrayRef result = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
  if (status == errSecSuccess || status == errSecItemNotFound) {
    NSArray *items = [NSArray arrayWithArray:(__bridge NSArray *)result];
    CFBridgingRelease(result);
    for (NSDictionary *item in items) {
      NSMutableDictionary *queryDelete = [[NSMutableDictionary alloc] initWithDictionary:item];
      queryDelete[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;

      OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDelete);
      if (status != errSecSuccess) {
        break;
      }
    }
  }
#else
  NSMutableDictionary *queryDelete = [self baseQueryGeneric];
  queryDelete[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
  queryDelete[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDelete);
  if (status != errSecSuccess) {
    return;
  }
#endif
}


- (void)clearAllInternet {
#if TARGET_OS_IPHONE
    NSDictionary *query = [self queryFindAllInternet:nil];
  CFArrayRef result = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
  if (status == errSecSuccess || status == errSecItemNotFound) {
    NSArray *items = [NSArray arrayWithArray:(__bridge NSArray *)result];
    CFBridgingRelease(result);
    for (NSDictionary *item in items) {
      NSMutableDictionary *queryDelete = [[NSMutableDictionary alloc] initWithDictionary:item];
      queryDelete[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;

      OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDelete);
      if (status != errSecSuccess) {
        break;
      }
    }
  }
#else
  NSMutableDictionary *queryDelete = [self baseQueryInternet];
  queryDelete[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;
  queryDelete[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDelete);
  if (status != errSecSuccess) {
    return;
  }
#endif
}

+ (A0SimpleKeychain *)keychain {
    return [[A0SimpleKeychain alloc] init];
}

+ (A0SimpleKeychain *)keychainWithService:(NSString *)service {
    return [[A0SimpleKeychain alloc] initWithService:service];
}

+ (A0SimpleKeychain *)keychainWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    return [[A0SimpleKeychain alloc] initWithService:service accessGroup:accessGroup];
}

#pragma mark - Utility methods

- (CFTypeRef)accessibility {
    CFTypeRef accessibility;
    switch (self.defaultAccessiblity) {
        case A0SimpleKeychainItemAccessibleAfterFirstUnlock:
            accessibility = kSecAttrAccessibleAfterFirstUnlock;
            break;
        case A0SimpleKeychainItemAccessibleAlways:
            accessibility = kSecAttrAccessibleAlways;
            break;
        case A0SimpleKeychainItemAccessibleAfterFirstUnlockThisDeviceOnly:
            accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
            break;
        case A0SimpleKeychainItemAccessibleAlwaysThisDeviceOnly:
            accessibility = kSecAttrAccessibleAlwaysThisDeviceOnly;
            break;
#if TARGET_OS_IPHONE
        case A0SimpleKeychainItemAccessibleWhenPasscodeSetThisDeviceOnly:
#ifdef __IPHONE_8_0
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) { //iOS 8
                accessibility = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly;
            } else { //iOS <= 7.1
                accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
            }
#else
            accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
#endif
#endif
            break;
        case A0SimpleKeychainItemAccessibleWhenUnlocked:
            accessibility = kSecAttrAccessibleWhenUnlocked;
            break;
        case A0SimpleKeychainItemAccessibleWhenUnlockedThisDeviceOnly:
            accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
            break;
        default:
            accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
    }
    return accessibility;
}

- (NSString*)stringForSecStatus:(OSStatus)status {

    switch(status) {
        case errSecSuccess:
            return NSLocalizedStringFromTable(@"errSecSuccess: No error", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecUnimplemented:
            return NSLocalizedStringFromTable(@"errSecUnimplemented: Function or operation not implemented", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecParam:
            return NSLocalizedStringFromTable(@"errSecParam: One or more parameters passed to the function were not valid", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecAllocate:
            return NSLocalizedStringFromTable(@"errSecAllocate: Failed to allocate memory", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecNotAvailable:
            return NSLocalizedStringFromTable(@"errSecNotAvailable: No trust results are available", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecAuthFailed:
            return NSLocalizedStringFromTable(@"errSecAuthFailed: Authorization/Authentication failed", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecDuplicateItem:
            return NSLocalizedStringFromTable(@"errSecDuplicateItem: The item already exists", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecItemNotFound:
            return NSLocalizedStringFromTable(@"errSecItemNotFound: The item cannot be found", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecInteractionNotAllowed:
            return NSLocalizedStringFromTable(@"errSecInteractionNotAllowed: Interaction with the Security Server is not allowed", @"SimpleKeychain", @"Possible error from keychain. ");
        case errSecDecode:
            return NSLocalizedStringFromTable(@"errSecDecode: Unable to decode the provided data", @"SimpleKeychain", @"Possible error from keychain. ");
        default:
            return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Unknown error code %d", @"SimpleKeychain", @"Possible error from keychain. "), status];
    }
}

#pragma mark - Query Dictionary Builder methods

- (NSMutableDictionary *)baseQueryGeneric {
    NSMutableDictionary *attributes = [@{
                                         (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                         (__bridge id)kSecAttrService: self.service,
                                         } mutableCopy];
#if !TARGET_IPHONE_SIMULATOR
    if (self.accessGroup) {
        attributes[(__bridge id)kSecAttrAccessGroup] = self.accessGroup;
    }
#endif
    
    if (self.icloudSync) {
        attributes[(__bridge id)kSecAttrSynchronizable] = self.icloudSync ? (__bridge id)kCFBooleanTrue : (__bridge id)kCFBooleanFalse;
    }

    return attributes;
}

- (NSMutableDictionary *)baseQueryInternet {
    NSMutableDictionary *attributes = [@{
                                         (__bridge id)kSecClass: (__bridge id)kSecClassInternetPassword,
                                         } mutableCopy];
#if !TARGET_IPHONE_SIMULATOR
    if (self.accessGroup) {
        attributes[(__bridge id)kSecAttrAccessGroup] = self.accessGroup;
    }
#endif
    
    if (self.icloudSync) {
        attributes[(__bridge id)kSecAttrSynchronizable] = self.icloudSync ? (__bridge id)kCFBooleanTrue : (__bridge id)kCFBooleanFalse;
    }

    return attributes;
}


- (NSDictionary *)queryFindAllGeneric:( NSString * _Nullable )message {
    NSMutableDictionary *query = [self baseQueryGeneric];
    [query addEntriesFromDictionary:@{
                                     (__bridge id)kSecReturnAttributes: @YES,
                                     (__bridge id)kSecReturnData: @YES,
                                     (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
                                     }];
    #if TARGET_OS_IPHONE
        if (message) {
            query[(__bridge id)kSecUseOperationPrompt] = message;
        }
    #endif
    return query;
}


- (NSDictionary *)queryFindAllInternet:(NSString *)message{
    NSMutableDictionary *query = [self baseQueryInternet];
    [query addEntriesFromDictionary:@{
                                     (__bridge id)kSecReturnAttributes: @YES,
                                     (__bridge id)kSecReturnData: @YES,
                                     (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
                                     }];
    #if TARGET_OS_IPHONE
        if (message) {
            query[(__bridge id)kSecUseOperationPrompt] = message;
        }
    #endif
    return query;
}

- (NSDictionary *)queryFindAllInternetByUrl:(NSString *)url message:(NSString *)message {
    NSMutableDictionary *query = [self baseQueryInternet];
    [query addEntriesFromDictionary:@{
                                     (__bridge id)kSecAttrServer: url,
                                     (__bridge id)kSecReturnAttributes: @YES,
                                     (__bridge id)kSecReturnData: @YES,
                                     (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll,
                                     }];
    #if TARGET_OS_IPHONE
        if (message) {
            query[(__bridge id)kSecUseOperationPrompt] = message;
        }
    #endif
    return query;
}


- (NSDictionary *)queryFindGenericByKey:(NSString *)key message:(NSString *)message {
    NSAssert(key != nil, @"Must have a valid non-nil key");
    NSMutableDictionary *query = [self baseQueryGeneric];
    query[(__bridge id)kSecAttrAccount] = key;
#if TARGET_OS_IPHONE
    if (message) {
        query[(__bridge id)kSecUseOperationPrompt] = message;
    }
#endif
    return query;
}

- (NSDictionary *)queryFindInternetByKey:(NSString *)key message:(NSString *)message {
    NSAssert(key != nil, @"Must have a valid non-nil key");
    NSMutableDictionary *query = [self baseQueryGeneric];
    query[(__bridge id)kSecAttrAccount] = key;
#if TARGET_OS_IPHONE
    if (message) {
        query[(__bridge id)kSecUseOperationPrompt] = message;
    }
#endif
    return query;
}

- (NSDictionary *)queryFindByUrl:(NSString *)url message:(NSString *)message {
    NSAssert(url != nil, @"Must have a valid non-nil url");
    NSMutableDictionary *query = [self baseQueryInternet];
    query[(__bridge id)kSecAttrServer] = url;
#if TARGET_OS_IPHONE
    if (message) {
        query[(__bridge id)kSecUseOperationPrompt] = message;
    }
#endif
    return query;
}

- (NSDictionary *)queryFindByUrlandKey:(NSString *)url withkey:(NSString *)key message:(NSString *)message {
    NSAssert(url != nil && key != nil, @"Must have a valid non-nil url");
    NSMutableDictionary *query = [self baseQueryInternet];
    [query addEntriesFromDictionary:@{
                                          (__bridge id)kSecReturnData: @YES,
                                          (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                                          (__bridge id)kSecAttrAccount: key,
                                          (__bridge id)kSecAttrServer: url,
                                          }];
    #if TARGET_OS_IPHONE
        if (self.useAccessControl) {
            if (message && floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
                query[(__bridge id)kSecUseOperationPrompt] = message;
            }
        }
    #endif
    return query;
}

- (NSDictionary *)queryUpdateValue:(NSData *)data message:(NSString *)message {
    if (message) {
        return @{
#if TARGET_OS_IPHONE
                 (__bridge id)kSecUseOperationPrompt: message,
#endif
                 (__bridge id)kSecValueData: data,
                 };
    } else {
        return @{
                 (__bridge id)kSecValueData: data,
                 };
    }
}

- (NSDictionary *)queryNewGenericKey:(NSString *)key value:(NSData *)value {
    NSMutableDictionary *query = [self baseQueryGeneric];
    query[(__bridge id)kSecAttrAccount] = key;
    query[(__bridge id)kSecValueData] = value;
#if TARGET_OS_IPHONE
#ifdef __IPHONE_8_0
    if (self.useAccessControl && floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        CFErrorRef error = NULL;
        SecAccessControlRef accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, [self accessibility], kSecAccessControlUserPresence, &error);
        if (error == NULL || accessControl != NULL) {
            query[(__bridge id)kSecAttrAccessControl] = (__bridge_transfer id)accessControl;
            query[(__bridge id)kSecUseNoAuthenticationUI] = @YES;
        }
    } else {
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)[self accessibility];
    }
#else
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)[self accessibility];
#endif
#endif
    return query;
}

- (NSDictionary *)queryNewInternetKey:(NSString *)key value:(NSData *)value url:(NSString *)url {
    NSMutableDictionary *query = [self baseQueryInternet];
    query[(__bridge id)kSecAttrAccount] = key;
    query[(__bridge id)kSecValueData] = value;
    query[(__bridge id)kSecAttrServer] = url;
#if TARGET_OS_IPHONE
#ifdef __IPHONE_8_0
    if (self.useAccessControl && floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        CFErrorRef error = NULL;
        SecAccessControlRef accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, [self accessibility], kSecAccessControlUserPresence, &error);
        if (error == NULL || accessControl != NULL) {
            query[(__bridge id)kSecAttrAccessControl] = (__bridge_transfer id)accessControl;
            query[(__bridge id)kSecUseNoAuthenticationUI] = @YES;
        }
    } else {
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)[self accessibility];
    }
#else
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)[self accessibility];
#endif
#endif
    return query;
}


- (NSDictionary *)queryFetchOneByUrlandKey:(NSString *)url withkey:(NSString *)key message:(NSString *)message {
    NSAssert(url != nil && key != nil, @"Must have a valid non-nil url");
    NSMutableDictionary *query = [self baseQueryInternet];
    query[(__bridge id)kSecAttrAccount] = key;
    query[(__bridge id)kSecAttrServer] = url;
#if TARGET_OS_IPHONE
    if (message) {
        query[(__bridge id)kSecUseOperationPrompt] = message;
    }
#endif
    return query;
}


- (NSDictionary *)queryFetchOneGenericByKey:(NSString *)key message:(NSString *)message {
    NSMutableDictionary *query = [self baseQueryGeneric];
    [query addEntriesFromDictionary:@{
                                      (__bridge id)kSecReturnData: @YES,
                                      (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                                      (__bridge id)kSecAttrAccount: key,
                                      }];
#if TARGET_OS_IPHONE
    if (self.useAccessControl) {
        if (message && floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
            query[(__bridge id)kSecUseOperationPrompt] = message;
        }
    }
#endif

    return query;
}

- (NSDictionary *)queryFetchOneInternetByKey:(NSString *)key message:(NSString *)message {
    NSMutableDictionary *query = [self baseQueryInternet];
    [query addEntriesFromDictionary:@{
                                      (__bridge id)kSecReturnData: @YES,
                                      (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
                                      (__bridge id)kSecAttrAccount: key,
                                      }];
#if TARGET_OS_IPHONE
    if (self.useAccessControl) {
        if (message && floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
            query[(__bridge id)kSecUseOperationPrompt] = message;
        }
    }
#endif

    return query;
}
@end
