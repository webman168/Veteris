//
//  NIB/storyboard compatibility for iOS 5–6. Precompiled storyboards may set
//  KVC keys that did not exist until iOS 7+; swallow them so launch does not abort.
//

#import <UIKit/UIKit.h>

static NSSet *VeterisIgnoredNibKeys(void) {
    static NSSet *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [NSSet setWithObjects:
                @"automaticallyAdjustsScrollViewInsets",
                @"edgesForExtendedLayout",
                @"barTintColor",
                @"selectedImageTintColor",
                @"tintColor",
                @"estimatedRowHeight",
                @"estimatedSectionFooterHeight",
                @"estimatedSectionHeaderHeight",
                @"adjustsLetterSpacingToFit",
                @"separatorInsetReference",
                @"semanticContentAttribute",
                @"contentInsetAdjustmentBehavior",
                @"scrollIndicatorInsetsAdjustmentBehavior",
                @"insetsContentViewsToSafeArea",
                @"layoutMarginsAreDirectional",
                @"fontMaximumPointSizeAfterScaling",
                @"fontPointSizeForScaling",
                @"fontTextStyleForScaling",
                @"maskedCorners",
                @"backgroundConfiguration",
                @"buttonConfiguration",
                @"symbolImageConfiguration",
                @"symbolConfiguration",
                @"largeContentTitle",
                @"largeContentImage",
                @"sectionHeaderTopPadding",
                @"cornerRadius",
                @"strokeColor",
                @"strokeWidth",
                @"strokeOutset",
                @"strokeLocation",
                @"strokeColorTransformerIdentifier",
                @"backgroundColorTransformerIdentifier",
                @"imageContentMode",
                @"visualEffect",
                @"visualEffectGroupName",
                @"visualEffectblurClippingMode",
                @"configurationAPI",
                @"backgroundInsets",
                @"edgesAddingLayoutMarginsToBackgroundInsets",
                // Auto Layout archive keys on iOS 6 (ignored by legacy runtime)
                @"contentHuggingPriority",
                @"horizontalHuggingPriority",
                @"verticalHuggingPriority",
                @"contentCompressionResistancePriority",
                @"horizontalCompressionResistancePriority",
                @"verticalCompressionResistancePriority",
                @"searchBarTranslucence",
                @"definesPresentationContext",
                nil];
    });
    return keys;
}

@implementation NSObject (VeterisLegacyNibCompat)

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([VeterisIgnoredNibKeys() containsObject:key]) {
        return;
    }
#if DEBUG
    NSLog(@"VeterisLegacyNibCompat: ignoring undefined key '%@' on %@", key, [self class]);
#endif
}

@end

@interface UINavigationBar (VeterisLegacyNibCompatBarTint)
- (void)setBarTintColor:(UIColor *)color;
@end

@implementation UINavigationBar (VeterisLegacyNibCompatBarTint)
- (void)setBarTintColor:(UIColor *)color {
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        [self setTintColor:color];
    }
}
@end
