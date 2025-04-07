//
//  Hooper.h
//  Hooper
//
//  Created by Alexandra (@Traurige)
//

#import <UIKit/UIKit.h>
#import <substrate.h>
#import "../Preferences/PreferenceKeys.h"
#import "../Preferences/NotificationKeys.h"

NSUInteger pageIndex = 0;

NSUserDefaults* preferences;
BOOL pfEnabled;
NSMutableDictionary* pfLabelNames;

@interface SBIconListView : UIView
@property(nonatomic, retain)UILabel* hooperPageLabel;
@property(nonatomic, retain)UITapGestureRecognizer* hooperPageLabelTap;
- (void)editPageLabel:(UITapGestureRecognizer *)recognizer;
@end

@interface SBFolderView : UIView
@property(nonatomic, readonly)long long currentPageIndex;
@end

@interface SBRootFolderView : SBFolderView
@end

@interface SBHDefaultIconListLayoutProvider : NSObject
@end

@interface SBIconListGridLayout : NSObject
@end

@interface SBIconListGridLayoutConfiguration : NSObject
@property(nonatomic, assign)UIEdgeInsets portraitLayoutInsets;
@end
