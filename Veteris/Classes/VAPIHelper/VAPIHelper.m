//
//  VAPIHelper.m
//  Veteris
//
//  Created by electimon on 6/7/19.
//  Copyright (c) 2019-22 Electimon. All rights reserved.
//

#include <Foundation/NSBundle.h>
#include <objc/NSObjCRuntime.h>
#import "../../Clutch/ApplicationLister.h"
#import "VAPIHelper.h"
#import "../Protos/Application.h"
#import <MacTypes.h>
#include <dlfcn.h>
#import <sys/sysctl.h>
#import "../../AppDelegate.h"
#import "../../BBHTTP/BBHTTP.h"
#import "../../BBHTTP/BBHTTPRequest+Convenience.h"
#import "./../AppInfo/AppInfo.h"
#import "../Protos/Version.h"
#import "../Protos/Update.h"
#import "../ProtoStack.h"
#import "../../BBHTTP/Cocoa/BBURLProtocol.h"
#import "BBHTTP/BBHTTPExecutor.h"
#import <arpa/inet.h>
#import <netdb.h>

@implementation VAPIHelper {
    NSCache *_staticCache;
    BBHTTPExecutor *_apiExecutor;
    BBHTTPExecutor *_iconExecutor;
    NSInteger _VAPIErrorMask;
}

@synthesize VAPIDeviceString = _deviceString;

static NSString *const API_PRODUCTION_STATIC_URL = @"http://api.victorlobe.me/veteris/";
static NSString *const API_PRODUCTION_BASE_URL = @"http://api.victorlobe.me/veteris/1.1/";
static NSString *const API_DEV_STATIC_URL = @"http://api.victorlobe.me/veteris-dev/";
static NSString *const API_DEV_BASE_URL = @"http://api.victorlobe.me/veteris-dev/1.1/";
static NSString *const VAPI_INSTALL_UUID_KEY = @"VAPIInstallUUID";
static NSString *const VAPI_DEV_MODE_ENABLED_KEY = @"veteris_dev_mode_enabled";
static NSString *const VAPI_SERVER_ENVIRONMENT_KEY = @"veteris_server_environment";
static NSString *const VAPI_SERVER_ENVIRONMENT_PRODUCTION = @"production";
static NSString *const VAPI_SERVER_ENVIRONMENT_DEV = @"dev";

+ (VAPIHelper*)sharedInstance
{
    static VAPIHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[VAPIHelper alloc] init];
        [sharedInstance setup];
    });
    return sharedInstance;
}

- (void)setup {
    [self setVAPIDeviceString];
    _staticCache = [[NSCache alloc] init];
    [_staticCache setTotalCostLimit:1024 * 1024 * 50]; // 50MB
    _apiExecutor = [[BBHTTPExecutor alloc] initWithId:@"VAPIHelper-API"];
    _apiExecutor.maxParallelRequests = 3;
    _apiExecutor.manageNetworkActivityIndicator = true;
    _iconExecutor = [[BBHTTPExecutor alloc] initWithId:@"VAPIHelper-Icons"];
    _iconExecutor.maxParallelRequests = 4;
    _iconExecutor.manageNetworkActivityIndicator = false;
    NSURL *apiURL = [NSURL URLWithString:[VAPIHelper getApiBaseURL]];
    NSString *apiHost = [apiURL host];
    if ([apiHost isEqualToString:@"apis.yzu.moe"]) {
        NSString *host = [self resolveHost:apiHost];
        if (host != nil) {
            [BBHTTPExecutor setResolvePolicy:apiHost withIP:host];
        }
    }
}

- (NSString *)resolveHost:(NSString *)host {
    struct hostent *host_entry = gethostbyname([host UTF8String]);
    if (host_entry == NULL || host_entry->h_addr_list == NULL || host_entry->h_addr_list[0] == NULL) {
        return nil;
    }
    char *buff;
    buff = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
    if (buff == NULL || strlen(buff) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:buff];
}

+ (NSString *)getApiStaticURL {
    if ([VAPIHelper isDevModeEnabled] && [[VAPIHelper getServerEnvironment] isEqualToString:VAPI_SERVER_ENVIRONMENT_DEV]) {
        return API_DEV_STATIC_URL;
    }
    return API_PRODUCTION_STATIC_URL;
}

+ (NSString *)getApiBaseURL {
    if ([VAPIHelper isDevModeEnabled] && [[VAPIHelper getServerEnvironment] isEqualToString:VAPI_SERVER_ENVIRONMENT_DEV]) {
        return API_DEV_BASE_URL;
    }
    return API_PRODUCTION_BASE_URL;
}

+ (BOOL)isDevModeEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:VAPI_DEV_MODE_ENABLED_KEY];
}

+ (void)setDevModeEnabled:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:VAPI_DEV_MODE_ENABLED_KEY];
    if ([defaults objectForKey:VAPI_SERVER_ENVIRONMENT_KEY] == nil) {
        [defaults setObject:VAPI_SERVER_ENVIRONMENT_PRODUCTION forKey:VAPI_SERVER_ENVIRONMENT_KEY];
    }
    [defaults synchronize];
}

+ (NSString *)getServerEnvironment {
    NSString *environment = [[NSUserDefaults standardUserDefaults] stringForKey:VAPI_SERVER_ENVIRONMENT_KEY];
    if ([environment isEqualToString:VAPI_SERVER_ENVIRONMENT_DEV]) {
        return VAPI_SERVER_ENVIRONMENT_DEV;
    }
    return VAPI_SERVER_ENVIRONMENT_PRODUCTION;
}

+ (void)setServerEnvironment:(NSString *)environment {
    if (![environment isEqualToString:VAPI_SERVER_ENVIRONMENT_DEV]) {
        environment = VAPI_SERVER_ENVIRONMENT_PRODUCTION;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:environment forKey:VAPI_SERVER_ENVIRONMENT_KEY];
    [defaults synchronize];
    [VAPIHelper resetNetworkState];
}

+ (void)resetNetworkState {
    [[VAPIHelper sharedInstance] clearStaticCache];
}

- (void)clearStaticCache {
    [_staticCache removeAllObjects];
}

+ (NSString *)installUUID {
    static NSString *installUUID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        installUUID = [[defaults stringForKey:VAPI_INSTALL_UUID_KEY] copy];
        if (installUUID == nil || [installUUID length] == 0) {
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            installUUID = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
            CFRelease(uuid);
            [defaults setObject:installUUID forKey:VAPI_INSTALL_UUID_KEY];
            [defaults synchronize];
        }
    });
    return installUUID;
}


+ (NSDictionary *)getHeaders {
    AppDelegate *delegate = getDelegate();
    return [@{
        @"X-Veteris-Device" : [VAPISS VAPIDeviceString],
        @"X-Veteris-UUID" : [VAPIHelper installUUID],
        @"X-Veteris-Version" : [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
        @"X-Veteris-Language" : [[NSLocale preferredLanguages] objectAtIndex:0],
    } mutableCopy];
}

#define VAPI_USE_BBHTTP_DIRECT
#ifdef VAPI_USE_BBHTTP_DIRECT
- (void)get:(NSString *)endpoint path:(NSString *)path iconTraffic:(BOOL)iconTraffic completion:(void (^)(NSData *data, NSError *error))completion {
    BBHTTPExecutor *executor = iconTraffic ? _iconExecutor : _apiExecutor;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *reqHeaders = [VAPIHelper getHeaders];
        BBHTTPRequest *request = [[BBHTTPRequest alloc] initWithTarget:[NSString stringWithFormat:@"%@%@", endpoint, path] andVerb:@"GET"];
        for (id key in reqHeaders) {
            [request setValue:[reqHeaders valueForKey:key] forHeader:key];
        }
        request.finishBlock = ^(BBHTTPRequest *request) {
            if ([request hasSuccessfulResponse] || request.responseStatusCode == 503) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(request.response.content, nil);
                });
            } else {
                debugLog(@"Error occurred: %@", request.error.localizedDescription);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, request.error);
                });
            }
        };
        [request downloadContentAsData];
        [executor executeRequest:request];
    });
}

- (void)get:(NSString *)endpoint path:(NSString *)path completion:(void (^)(NSData *data, NSError *error))completion {
    [self get:endpoint path:path iconTraffic:NO completion:completion];
}
#else // has broken network activity indicator
- (void)get:(NSString *)endpoint path:(NSString *)path completion:(void (^)(NSData *data, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [endpoint stringByReplacingOccurrencesOfString:@"https" withString:@"bbhttps"], path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *reqHeaders = [VAPIHelper getHeaders];
    for (id key in reqHeaders) {
        [request setValue:[reqHeaders valueForKey:key] forHTTPHeaderField:key];
    }
    [request setHTTPMethod:@"GET"];
    [NSURLProtocol registerClass:[BBURLProtocol class]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error != nil) {
            debugLog(@"Error occurred: %@", error.localizedDescription);
        }
        completion(data, error);
    }];
}
#endif

// this implements cached version for static assets
// its fine to cache images like this because they are unique per bundleid
- (void)getCached:(NSString *)endpoint path:(NSString *)path completion:(void (^)(NSData *data, NSError *error))completion {
    if (path == nil || [path length] == 0) {
        completion(nil, [NSError errorWithDomain:@"VAPIHelper"
                                            code:NSURLErrorBadURL
                                        userInfo:@{NSLocalizedDescriptionKey: @"empty asset path"}]);
        return;
    }
    bool isImage = [[path lastPathComponent] rangeOfString:@"png"].location != NSNotFound;
    BOOL isAbsoluteURL = [path hasPrefix:@"http://"] || [path hasPrefix:@"https://"];
    NSString *endpointToUse = isAbsoluteURL ? @"" : endpoint;
    NSString *pathToUse = isAbsoluteURL ? path : [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", endpointToUse, pathToUse];
    if (isImage) {
        NSData *cachedData = [_staticCache objectForKey:cacheKey];
        if (cachedData != nil) {
            completion(cachedData, nil);
            return;
        }
    }
    [self get:endpointToUse path:pathToUse iconTraffic:YES completion:^(NSData *data, NSError *error){
        if (data != nil && isImage) {
            [_staticCache setObject:data forKey:cacheKey];
        }
        completion(data, error);
    }];
}

- (void)getStatic:(NSString *)path completion:(void (^)(NSData *data, NSError *error))completion {
    [self getCached:[VAPIHelper getApiStaticURL] path:path completion:completion];
}

- (void)getStatic:(NSString *)path fallbackPath:(NSString *)fallbackPath completion:(void (^)(NSData *data, NSError *error))completion {
    [self getStatic:path completion:^(NSData *data, NSError *error) {
        if (error == nil && data != nil) {
            completion(data, nil);
            return;
        }
        if (fallbackPath == nil || [fallbackPath length] == 0 || [fallbackPath isEqualToString:path]) {
            completion(data, error);
            return;
        }
        debugLog(@"Primary static asset failed, trying fallback: %@ -> %@", path, fallbackPath);
        [self getCached:[VAPIHelper getApiStaticURL] path:fallbackPath completion:^(NSData *fallbackData, NSError *fallbackError) {
            if (fallbackError == nil && fallbackData != nil && path != nil) {
                BOOL pathIsAbsoluteURL = [path hasPrefix:@"http://"] || [path hasPrefix:@"https://"];
                NSString *primaryPathToUse = pathIsAbsoluteURL ? path : [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *primaryCacheKey = pathIsAbsoluteURL ? primaryPathToUse : [NSString stringWithFormat:@"%@%@", [VAPIHelper getApiStaticURL], primaryPathToUse];
                [_staticCache setObject:fallbackData forKey:primaryCacheKey];
            }
            completion(fallbackData, fallbackError);
        }];
    }];
}

- (void)getMessage:(NSString *)path completion:(void (^)(NSData *data, NSError *error))completion {
    [self get:[VAPIHelper getApiBaseURL] path:path completion:completion];
}

- (UIImage *)imageFromCache:(NSString *)url {
    BOOL isAbsoluteURL = [url hasPrefix:@"http://"] || [url hasPrefix:@"https://"];
    NSString *pathToUse = isAbsoluteURL ? url : [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *cacheKey = isAbsoluteURL ? pathToUse : [NSString stringWithFormat:@"%@%@", [VAPIHelper getApiStaticURL], pathToUse];
    NSData *cachedData = [_staticCache objectForKey:cacheKey];
    if (cachedData != nil) {
        return [UIImage imageWithData:cachedData];
    }
    return nil;
}

- (NSString *)getSysInfoByName:(char *)typeSpecifier {
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];

    free(answer);
    return results;
}

- (void)setVAPIDeviceString {
    AppDelegate *delegate = getDelegate();
    NSArray *deviceInfo = @[[self getSysInfoByName:"hw.model"], [self getSysInfoByName:"hw.machine"], [[UIDevice currentDevice] systemVersion]];
    _deviceString = [deviceInfo componentsJoinedByString:@"/"];
    debugLog(@"VAPI Device String: %@", _deviceString);
}

+ (void)checkForUpdates {
    [VAPISS getMessage:@"client/updates" completion:^(NSData *data, NSError *error) {
        if (error != nil) {
            debugLog(@"Error contacting server: %@", error.localizedDescription);
            alert(NSLocalizedString(@"Oops", nil), NSLocalizedString(@"ServerContactError", nil), VAPIHelperErrorNetwork);
        } else if (data != nil && [data length] > 1) {
            debugLog(@"Received update data");
            Update *upd = (Update *)CFBridgingRelease(decode([data bytes], [data length], UpdateResponse));
            if (upd == NULL) {
                debugLog(@"Error decoding UpdateMsg");
                return;
            }
            if (upd.version == nil || [upd.version length] == 0) {
                debugLog(@"Ignoring empty UpdateMsg");
                return;
            }
            if (upd.changelog == nil) {
                upd.changelog = @"";
            }
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSDictionary dictionaryWithObject:upd.changelog forKey:upd.version] forKey:@"latest_changelog"];
            [defaults synchronize];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Update Available!" message:[NSString stringWithFormat:@"New version %@ is available! Update now?", upd.version] delegate:getDelegate() cancelButtonTitle:@"Later" otherButtonTitles:@"Ok", nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        } else {
            debugLog(@"No data received");
        }
    }];
}

+ (void)showWhatsNewIfNeeded {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *latest_changelog = [defaults objectForKey:@"latest_changelog"];
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        debugLog(@"Latest changelog: %@", latest_changelog);
        debugLog(@"Current version: %@", currentVersion);
        if (latest_changelog != nil && [latest_changelog objectForKey:currentVersion] != nil) {
            NSString *changelog = [latest_changelog objectForKey:currentVersion];
            [YZAlert alert:NSLocalizedString(@"What's New", nil) message:changelog separator:@"\n"];
            [defaults removeObjectForKey:@"latest_changelog"];
            [defaults synchronize];
        } else {
            debugLog(@"No changelog found for current version");
        }
    });
}
@end
