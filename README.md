Choosy (Beta)
==================

[Substantial's introductory blog post](http://substantial.com/blog/2014/05/07/introducing-choosy-your-app-selector-for-ios/).

[Choosy official web site and video](http://choosy.substantial.com).

Choosy is an app-agnostic interface to communicate with other apps installed on a device. With Choosy, you can write one line of code:  

```objc
- (void)viewDidLoad:
{
  self.choosy = [Choosy new];
  [self.choosy registerUIElement:self.myTwitterButton
                       forAction:[ChoosyActionContext actionContextWithAppType:@"Twitter"
                                                                        action:@"show_profile"
                                                                    parameters:@{@"profile_screenname" : @"KarlTheFog", 
                                                                    			 @"callback_url" : @"yourappurl:"]];
}
```

to get automatic support for popular Twitter clients (screenshots are from the included Demo app): 

![Opening Twitter link](https://farm3.staticflickr.com/2938/13952473947_f78c23cd64_c.jpg) <br/>
([click here](https://farm3.staticflickr.com/2895/14135516781_2b85879666_o.gif) for the gif version)

Instead of writing code specific to each app you want to support (this includes 1st-party apps), you pass generic parameters. Choosy detects installed apps of that type and knows which parameters each app supports, passing only the supported parameters to each app.

Choosy allows users to select a favorite app, so they do not have to pick the app every time ([click here](https://farm8.staticflickr.com/7391/14115656296_ba32a6b45e_o.gif) for a gif showing the gesture).

To stay informed about new releases and API changes please follow [@choosyios](http://www.twitter.com/choosyios). To see supported URL schemes or make URL scheme contributions check out [choosy-data](https://github.com/substantial/choosy-data).

##Installing

You can download this repository and copy the Choosy folder to your project, but the best way to install Choosy is via CocoaPods. If you don't use CocoaPods yet, start by following [this guide](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking), except replace the `pod 'AFNetworking' ...` line with this:

```
pod 'Choosy', '< 2.0'
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
  [Choosy registerAppTypes:@[@"Twitter"]];
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

## Action Context

Use `ChoosyActionContext` objects to pass all information about the actions you want to execute. What we call 'action' here can also be thought of as 'external link', since you're really opening (linking to) an an external app. We prefer the word 'action' for two reasons. One, you typically don't just link to an app, but you want to perform an action with it, such as show a specific Twitter profile. And two, we have some cool long-term features planned that go beyond just opening apps ;)

For native apps, you can use any of the `actionContextWithAppType...` convenience initializers. If you pass just the app type via `actionContextWithAppType:`, Choosy will show apps of that type and just open them, passing no parameters.

Let's look at the most verbose initializer:

```objc
+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey
                                  action:(NSString *)actionKey
                              parameters:(NSDictionary *)parameters
                          appPickerTitle:(NSString *)appPickerTitle;
```

`appTypeKey` is a string like `@"Twitter"`, `@"Email"`, `@"Browser"`, `@"Maps"`, `@"Music"`, `@"RSS"`, `@"Contacts"`, `@"Weather"`, etc.
`actionKey` is a string like `@"show_profile"`, `@"compose"`, `@"directions"`, `@"browse"`, etc.
`parameters` is the list of parameters for that action. Being app-agnostic means that all keys are Choosy-specific, although we try to utilize keys from the most-prevalent app's URL scheme whenever possible. For example, some of our parameter names for Twitter actions are same as Tweetbot's, but that's just because we liked their names and they have the best-documented URL scheme :)
`appPickerTitle` is the text to be displayed at the top of Choosy's UI. This is optional; use it if you want to override the default. Currently, the default text is just app type name, but we plan on making it smarter in the near future, such as showing name of action requested or even some key parameter value related to the action, such as the Twitter handle of the profile that's about to be opened.

What you want to do is to pass as many parameters as you need for your best-case scenario. For example, include a callback url even if you are not sure if any apps support it. Choosy will take care of skipping parameters for apps that don't support them.



## The Magic

The first time you hook Choosy up, it may feel like black magic. You wrote a line of code and boom, you app supports linking to all major Twitter clients _and_ users can pick their favorite app! How does it know about all the apps? How does it instantly know when user deletes an app or installs a new app? (oh - spoiler alert!)

The concept is very simple - combine a web service that knows all about apps with client code that pulls that information and calls UIApplication's `canOpenURL` for each app to create a list of installed apps. Add some multithreading, caching, icon downloads, a default UI, ability to select a default app, and remembering the previous list of installed apps in order to know when a new app shows up, and you get Choosy.

### Default Behavior

Choosy comes with data about all supported built-in apps and apps related to built-in services (Mail, Safari, Maps, Twitter, etc.). This means that no connection is required for Choosy to work at least as good as URLs work today; so if a web link is tapped, Choosy will just open Safari. I.e., the worst-case behavior is same as when Choosy isn't present. When additional data is downloaded, however, and more than one app is installed for a given app type, then Choosy lets users pick an app.

Interactions:
* A _tap_ shows installed apps for a given app type (Browser, Navigation, Email, Twitter, etc.). Here users can also select their favorite app.
* A _long press_ resets the default app selection, if any, and presents the app selection again. Note that long press will show the app drawer interface even if just one app is installed.
* If the app designated as default/favorite is deleted, the user is presented with choices the next time they tap the link.
* If an app is designated as default/favorite for a certain app type, and new app of same type is installed (such as a new Twitter client), the user is presented with choices again so they have the opportunity to select the newly installed app.

### Caching

Currently, Choosy only checks for new data if the cache is over 24 hours old _or_ `CHOOSY_DEVELOPMENT_MODE` flag is set to 1. The cache period could be configurable in the future.

### Downloading

In order to require as few lines of code from you as possible, Choosy is completely automatic when it comes to updating itself. Every time you register an app type or a UI element with Choosy, it kicks off an update process. But even if you have multiple Twitter links that you register at the same time, Choosy will only download Twitter app type data once. It will similarly download app icon for the same app just once, regardless of how many types the app belongs to (for example, Safari is part of both Browser and Twitter app types). If connection drops, Choosy will resume when connection is reestablished.

## Limitations

Choosy is made for non-jailbroken devices. As such, it's subject to app sandboxing rules. Until we figure out a way, users' defaults are stored on a per-app basis. If they select Tweetbot as their default Twitter client in your app, they will have to select it as default again in another app. This is one of the main reasons why we wanted to have the cleanest, simplest UI and affordances possible; if users need to pick default apps multiple times (potentially), the process should be as painless and as consistent as possible.

Again due to sandboxing, Choosy must store a set of app icons within each app that implements it. We do try to be diligent iOS citizens and store all icons (and all info about other apps) in the Cache folder. So if the phone is ever running out of space, we can sleep well knowing we haven't contributed to the problem.

We'll see if iOS 8 mitigates our data-sharing woes! :)

## Examples

We have a [short video with code](http://choosy.substantial.com). For raw, up-to-date information on supported apps, actions, and aparameters see the [choosy-data](https://github.com/substantial/choosy-data) repository. We hope to have a site that auto-generates documentation based on the raw files up and running by 1.0.

> More examples coming soon to this section!

## Customizing the UI

The default UI follows Apple's aesthetic, and consistency is gold (sometimes as much as $140b worth of gold). This framework is useful when it works the same way across all apps. So if you come up with a UI with better affordances, etc. - please do submit a pull request or just contact us to exchange ideas.

But if you're dying to roll your own UI, you totes can. Just be sure to notify Choosy when an app is selected, etc. as per `ChoosyPickerDelegate`. Implementation can come in many forms, but here's a skeleton for a sample implementation:

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

## Web Views

Choosy can work for links inside web views, whether your app just hosts a web view or is a web view-based app altogether. However, `UIWebView` does not notify anyone when a link was long-pressed; as such, whenever you're dealing with web view links, you should disable the default app selection feature:

```objc
self.choosy.allowsDefaultAppSelection = NO;
```

More on this soon...

## Roadmap

Coming soon:

* Better accessibility support
* Using iTunes API to download icons straight from Apple
* Better support for iPad (Choosy does work on iPad, but the design is not iPad-optimized)
* Support for more apps, more actions, and more parameters ([you can help here!](https://github.com/substantial/choosy-data))
* Tests
* The ability to further filter down apps by virtue of support of a certain action, not just by app type membership
* A UI to navigate all available parameters, etc. (so you don't have to browse [raw JSON files](https://github.com/substantial/choosy-data))
* Tasteful, minimal UI animations: the whole UI could use being slightly more lively
* Localization (for text related to selection of default app)
* Better Web View support, and way better support for creation of `ChoosyActionContext` objects out of URLs.
* Upside-down orientation support on iPhone/iPod and switching to/from it
* We haven't seen any memory issues, but there are singletons under the hood, so memory management of those can probably be improved. No special time has been spent on this yet
* Auto-regression for icons; so when @3x comes, we're at least using @2x icons until better ones are available

Moonshots:

* Safe data exchange between apps
* UI for adding/editing app information (rather than creating JSON files))

## Contribute!

We would _love_ your help with the items above! You're awesome.

Code critiques, pull requests, and ideas are more than welcome! Let's make native inter-app linking as easy as it can be, at least within 3rd-party apps. You can also contact us at choosy@substantial.com.

To contribute new url schemes or updates to url schemes submit pull requests to the [choosy-data](https://github.com/substantial/choosy-data) repository.
