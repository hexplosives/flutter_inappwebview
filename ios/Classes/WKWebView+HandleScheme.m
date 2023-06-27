//
//  WKWebView+HandleScheme.m
//  WKProxy
//
//  Created by blackfin on 2023/5/11.
//

#import "WKWebView+HandleScheme.h"
#import <objc/runtime.h>

@implementation WKWebView (HandleScheme)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getClassMethod(self, @selector(handlesURLScheme:));
        Method exchangeMethod = class_getClassMethod(self, @selector(browserURLSchemeHandler:));
        method_exchangeImplementations(originalMethod, exchangeMethod);
    });
}

+ (BOOL) browserURLSchemeHandler: (NSString *)urlScheme {
    if ([urlScheme isEqualToString:@"http"] ||
        [urlScheme isEqualToString:@"https"]) {
        return NO;
    }
    else {
        return [self browserURLSchemeHandler: urlScheme];
    }
//    return YES;
    
}
@end
