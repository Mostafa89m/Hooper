//
//  Hooper.m
//  Hooper
//
//  Created by Alexandra (@Traurige)
//

#import "Hooper.h"

#pragma mark - SBIconListView class properties

static UILabel* hooperPageLabel(SBIconListView* self, SEL _cmd) {
    return (UILabel *)objc_getAssociatedObject(self, (void *)hooperPageLabel);
};
static void setHooperPageLabel(SBIconListView* self, SEL _cmd, UILabel* rawValue) {
    objc_setAssociatedObject(self, (void *)hooperPageLabel, rawValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static UITapGestureRecognizer* hooperPageLabelTap(SBIconListView* self, SEL _cmd) {
    return (UITapGestureRecognizer *)objc_getAssociatedObject(self, (void *)hooperPageLabelTap);
};
static void setHooperPageLabelTap(SBIconListView* self, SEL _cmd, UITapGestureRecognizer* rawValue) {
    objc_setAssociatedObject(self, (void *)hooperPageLabelTap, rawValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - SBIconListView class hooks

void (* orig_SBIconListView_didMoveToWindow)(SBIconListView* self, SEL _cmd);
void override_SBIconListView_didMoveToWindow(SBIconListView* self, SEL _cmd) {
    orig_SBIconListView_didMoveToWindow(self, _cmd);

    // make sure it's a home screen icon list view
    if (![NSStringFromClass([[self superview] class]) isEqualToString:@"SBIconScrollView"]) {
        return;
    }

    if (![self hooperPageLabel]) {
        [self setHooperPageLabel:[[UILabel alloc] init]];
        [[self hooperPageLabel] setFont:[UIFont systemFontOfSize:30 weight:UIFontWeightSemibold]];
        [[self hooperPageLabel] setTextColor:[UIColor whiteColor]];

        // every label text is saved in a dictionary with the key being the page index
        if ([pfLabelNames objectForKey:[NSString stringWithFormat:@"%lu", pageIndex]]) {
            [[self hooperPageLabel] setText:[pfLabelNames objectForKey:[NSString stringWithFormat:@"%lu", pageIndex]]];
        } else {
            [[self hooperPageLabel] setText:@"New page"];
        }
        pageIndex += 1;

        [[self hooperPageLabel] setUserInteractionEnabled:YES];
        [self addSubview:[self hooperPageLabel]];

        [[self hooperPageLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [[[self hooperPageLabel] bottomAnchor] constraintEqualToAnchor:[self topAnchor] constant:90],
            [[[self hooperPageLabel] leadingAnchor] constraintEqualToAnchor:[self leadingAnchor] constant:(32)],
            [[[self hooperPageLabel] trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-32],
        ]];

        [self setHooperPageLabelTap:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editPageLabel:)]];
        [[self hooperPageLabel] addGestureRecognizer:[self hooperPageLabelTap]];
    }
}

void SBIconListView_editPageLabel(SBIconListView* self, SEL _cmd, UITapGestureRecognizer* recognizer) {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Editing page label" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    SBRootFolderView* folderView = (SBRootFolderView *)[[[self superview] superview] superview];

    UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        NSString* text = [[[alertController textFields] firstObject] text];
        NSString* trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmedText isEqualToString:@""]) {
            return;
        }

        [[self hooperPageLabel] setText:text];

        [pfLabelNames setObject:text forKey:[NSString stringWithFormat:@"%lld", [folderView currentPageIndex] - 100]];
        [preferences setObject:pfLabelNames forKey:kPreferenceKeyLabelNames];
    }];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alertController addAction:confirmAction];
    [alertController addAction:cancelAction];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
        [textField setPlaceholder:[NSString stringWithFormat:@"Page %lli", [folderView currentPageIndex] - 99]];
    }];

    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - SBHDefaultIconListLayoutProvider class hooks

SBIconListGridLayout* (* orig_SBHDefaultIconListLayoutProvider_makeLayoutForIconLocation)(SBHDefaultIconListLayoutProvider* self, SEL _cmd, NSString* iconLocation);
SBIconListGridLayout* override_SBHDefaultIconListLayoutProvider_makeLayoutForIconLocation(SBHDefaultIconListLayoutProvider* self, SEL _cmd, NSString* iconLocation) {
	SBIconListGridLayout* layout = orig_SBHDefaultIconListLayoutProvider_makeLayoutForIconLocation(self, _cmd, iconLocation);

	if ([iconLocation hasPrefix:@"SBIconLocationRoot"]) {
		SBIconListGridLayoutConfiguration* config = [layout valueForKey:@"_layoutConfiguration"];

        UIEdgeInsets originalInsets = [config portraitLayoutInsets];
        originalInsets.top += 22;

        [config setPortraitLayoutInsets:originalInsets];
	}

	return layout;
}

#pragma mark - Preferences

static void load_preferences() {
    preferences = [[NSUserDefaults alloc] initWithSuiteName:kPreferencesIdentifier];

    [preferences registerDefaults:@{
        kPreferenceKeyEnabled: @(kPreferenceKeyEnabledDefaultValue),
        kPreferenceKeyLabelNames: kPreferenceKeyLabelNamesDefaultValue
    }];

    pfEnabled = [[preferences objectForKey:kPreferenceKeyEnabled] boolValue];
    pfLabelNames = [[preferences objectForKey:kPreferenceKeyLabelNames] mutableCopy];
}

#pragma mark - Constructor

__attribute((constructor)) static void initialize() {
    load_preferences();

    if (!pfEnabled) {
        return;
    }

    class_addProperty(objc_getClass("SBIconListView"), "hooperPageLabel", (objc_property_attribute_t[]){{"T", "@\"UIImageView\""}, {"N", ""}, {"V", "_hooperPageLabel"}}, 3);
    class_addMethod(objc_getClass("SBIconListView"), @selector(setHooperPageLabel:), (IMP)&setHooperPageLabel, "v@:@");
    class_addMethod(objc_getClass("SBIconListView"), @selector(hooperPageLabel), (IMP)&hooperPageLabel, "@@:");
    class_addProperty(objc_getClass("SBIconListView"), "hooperPageLabelTap", (objc_property_attribute_t[]){{"T", "@\"UIImageView\""}, {"N", ""}, {"V", "_hooperPageLabelTap"}}, 3);
    class_addMethod(objc_getClass("SBIconListView"), @selector(setHooperPageLabelTap:), (IMP)&setHooperPageLabelTap, "v@:@");
    class_addMethod(objc_getClass("SBIconListView"), @selector(hooperPageLabelTap), (IMP)&hooperPageLabelTap, "@@:");

    class_addMethod(objc_getClass("SBIconListView"), @selector(editPageLabel:), (IMP)&SBIconListView_editPageLabel, "v@:");

    MSHookMessageEx(objc_getClass("SBIconListView"), @selector(didMoveToWindow), (IMP)&override_SBIconListView_didMoveToWindow, (IMP *)&orig_SBIconListView_didMoveToWindow);

    MSHookMessageEx(objc_getClass("SBHDefaultIconListLayoutProvider"), @selector(makeLayoutForIconLocation:), (IMP)&override_SBHDefaultIconListLayoutProvider_makeLayoutForIconLocation, (IMP *)&orig_SBHDefaultIconListLayoutProvider_makeLayoutForIconLocation);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)load_preferences, (CFStringRef)kNotificationKeyPreferencesReload, NULL, (CFNotificationSuspensionBehavior)kNilOptions);
}
