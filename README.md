Choosy
==================

With Choosy, you can define an action and let your users pick from their installed apps that support that action with just one line of code. Instead of writing code specific to each app you want to support (this includes 1st-party apps), you pass generic parameters for the type of app you're linking to ('types' means Twitter, Maps, Browser, Email, etc.). Choosy takes care of detecting installed apps of that type and which parameters each app supports, creating proper URL for each app, and executing that URL to open the app. Choosy works with both native apps and web view-based apps. By default, users can even select a favorite app and not have to pick it every time.

For more overview, please see Substantial's [blog post(TODO)]() introducing Choosy.

##Installing

You can download this repository and copy the Choosy folder to your project, but the best way to install Choosy is via CocoaPods. If you don't use CocoaPods yet, start by following [this guide](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking), except replace the `pod 'AFNetworking' ...` line with this:

```
pod 'Choosy', '>= 0.5'
```

## Using

###Auto-pilot

Using Choosy is as simple as importing the `Choosy.h` header file in your view controller, declaring a property to hold the object:

```objc
@property (nonatomic) Choosy *choosy;
```

and registering a UI component, such as a UIButton that links to someone's Twitter profile:

```objc
- (void)viewDidLoad:
{
  self.choosy = [Choosy new];
  [self.choosy registerUIElement:self.elonMuskTwitterButton
                       forAction:[ChoosyActionContext actionContextWithAppType:@"Twitter"
                                                                        action:@"show_profile"
                                                                    parameters:@{ @"profile_screenname" : @"elonmusk"]];
}
```

By default, Choosy will attach a tap and long-press gesture recognizers to the button. A tap presents user with app selection if no favorite app is selected; otherwise, it launches the favorite app. Long-press allows users to reset the favorite app setting and pick from installed apps again.

### Manual

Of course, you may want to execute your own code on tap or long-press. In that case, first register all app types you intend on using:

```objc
- (void)viewDidLoad
{
  ...
  [self.choosy registerAppTypes:@[@"Twitter"]];
}
```

Then, after your tap gesture-handling code, explicitly tell Choosy to get to work:

```objc
  [self.choosy handleAction:[ChoosyActionContext actionContextWithAppType:@"Twitter"
                                                                   action:@"show_profile"
                                                               parameters:@{ @"profile_screenname" : @"elonmusk"]];
```

After your long-press gesture-handling code, you need to call a different method:

```objc
  [self.choosy resetAppSelectionAndHandleAction:[ChoosyActionContext actionContextWithAppType:@"Twitter"
                                                                                       action:@"show_profile"
                                                                                   parameters:@{ @"profile_screenname" : @"elonmusk"]];
```

### The early bird gets the worm

The very first time Choosy hears about an app type, it goes and downloads information about it. That's near-instantaneous on any decent connection, and data is cached after the initial download, but what if first-time users are experiencing a slow connection? It's therefore best to tell Choosy as early as possible in the app lifecycle about all the various app types you will link to, such as in the app delegate. This will not block the main thread:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ...

    [Choosy registerAppTypes:@[@"Twitter", @"Email", @"Browser", @"Maps"]];

    return YES;
}
```

This way, by the time your users open a screen that has a Twitter link, for example, Choosy will have received information about Twitter app type and apps, checked which apps are installed, and downloaded icons for the installed apps.

### Which method to use
You can intermix `registerUiElement:forAction:` and `handleAction:` calls as you see fit. Just keep in mind that `registerUiElement:forAction:` registers the UI element for both tap and long-press gestures. So if you're manually handling one of these gestures and calling either `handleAction:` or `resetAppSelectionAndHandleAction:`, you need to override the other gesture as well and call the other method there. It's particularly easy to forget to handle a long press, leaving users without the ability to reset their defaults!

## Customizing the UI

The default UI follows Apple's aesthetic, and consistency is gold (sometimes as much as $140b worth of gold). This framework is useful when it works the same way across all apps. So if you come up with a UI with better affordances, etc. - please do submit a pull request or just contact us to exchange ideas.

But if you're dying to roll your own UI, you tots can. Just be sure to notify Choosy when an app is selected, etc. as per `ChoosyPickerDelegate`. Implementation can come in many forms, but here's a skeleton for a sample implementation:

### Step 1

Make your custom UI view controller. Header file:

```objc
#import "ChoosyPickerDelegate.h"

@interface MyCustomAppPickerViewController : UIViewController

@property (nonatomic, weak) id<ChoosyPickerDelegate> delegate;
@property (nonatomic) ChoosyPickerViewModel *choosyViewModel;

@end
```

Implementation file:

```objc
@implementation MyCustomAppPickerViewController

...

// let's say you have these methods hooked up to gesture recognizers
// and you're using collection view with MyAppCell objects to represent each cell

- (void)appTapped:(UITapGestureRecognizer *)gesture
{
	MyAppCell *cell = (MyAppCell *)gesture.view;
	NSString *appKey = cell.appKey;

	[self.delegate didSelectApp:appKey];
}
- (void)appLongPressed:(UILongPressGestureRecognizer *)gesture
{
    MyAppCell *cell = (MyAppCell *)gesture.view;
    NSString *appKey = cell.appKey;

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self.delegate didSelectDefaultApp:appKey];
            break;
        default:
            break;
    }
}

- (void)viewTapped:(UITapGestureRecognizer *)gesture
{
	CGPoint point = [gesture locationInView:self.view];

  // the tappedOutsideOfAppPickerVisibleArea method is up to you to implement
  // you can also add a swipe down gesture that also calls `didRequestPickerDismissal`, like the default UI has
	if ([self tappedOutsideOfAppPickerVisibleArea: point]) {
		[self.delegate didRequestPickerDismissal];
	}
}

@end
```

### Step 2

Make the view controller responsible for showing the custom app picker UI implement `ChoosyDelegate`, make that view controller the delegate of the Choosy instance it has a reference to, and implement `showCustomChoosyPickerWithModel:`:

```objc

#import "Choosy.h"
#import "MyCustomAppPickerViewController.h"

@interface MyViewController () <ChoosyDelegate, MyCustomAppPickerDelegate>
  @property (nonatomic) Choosy *choosy;
  @property (nonatomic) MyCustomAppPickerViewController *appPicker;
@end
@implementation MyViewController()

- (void)viewDidLoad
{
  self.choosy = [Choosy new];
  self.choosy.delegate = self;
  ...
}

#pragma mark ChoosyDelegate

- (void)showCustomChoosyPickerWithModel:(ChoosyPickerViewModel *)viewModel
{
  self.appPicker = [MyCustomAppPickerViewController new];
  appPicker.delegate = self;

  [self presentViewController:appPicker];
  ...
}

#pragma mark ChoosyPickerDelegate

- (void)didSelectAppWithKey:(NSString *)appKey
{
  [self.appPicker dismissViewControllerAnimated:YES completion:^{
    [self.choosy didSelectApp:appKey];
  }];
}

- (void)didSelectDefaultAppWithKey:(NSString *)appKey
{
  [self.appPicker dismissViewControllerAnimated:YES completion:^{
    [self.choosy didSelectDefaultApp:appKey];
  }];
}

- (void)didRequestPickerDismissal
{
  // just dismiss the app picker
  // no need to notify Choosy since we're handling the UI part manually
  [self.appPicker dismissViewControllerAnimated:YES completion:nil];
}
@end
```
