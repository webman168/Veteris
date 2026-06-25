#import "Update.h"

static NSString *VeterisStringFromProto(const char *value) {
    if (value == NULL) {
        return @"";
    }
    NSString *string = [NSString stringWithUTF8String:value];
    return string ?: @"";
}

@implementation Update
- (Update *)initFromUpdateProto:(UpdateMsg)updateProto {
    self = [super init];
    if (self) {
        self.version = VeterisStringFromProto(updateProto.version.arg);
        self.forceUpdate = updateProto.force;
        self.changelog = VeterisStringFromProto(updateProto.changelog.arg);
    }
    return self;
}
@end
