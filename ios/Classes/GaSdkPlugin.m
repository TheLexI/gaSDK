#import "GaSdkPlugin.h"
#if __has_include(<ga_sdk/ga_sdk-Swift.h>)
#import <ga_sdk/ga_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ga_sdk-Swift.h"
#endif

@implementation GaSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGaSdkPlugin registerWithRegistrar:registrar];
}
@end
