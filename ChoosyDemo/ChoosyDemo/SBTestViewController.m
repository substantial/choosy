//
//  SBTestViewController.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 1/31/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBTestViewController.h"
#import "Reachability.h"
#import "SBCustomPickerViewController.h"
@import MapKit;

@interface SBTestViewController () <SBChoosyPickerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *navigateButton;

@property (weak, nonatomic) IBOutlet UIButton *navigateButtonCustom;
@property (weak, nonatomic) IBOutlet UIButton *emailButtonCustom;
@property (weak, nonatomic) IBOutlet UIButton *twitterButtonCustom;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (nonatomic) SBCustomPickerViewController *customAppPicker;
@property (nonatomic) SBChoosyPickerViewModel *pickerViewModel;

@property (nonatomic) SBChoosy *choosy;

@end

@interface SFOfficeAnnotation : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@implementation SBTestViewController

// code for this demo

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.choosy = [SBChoosy new];
    self.choosy.delegate = self;
    SBChoosyActionContext *navigateAction = [SBChoosyActionContext contextWithAppType:@"Maps"
                                                                               action:@"directions"
                                                                           parameters:@{@"end_address" : @"25 Taylor St, San Francisco, CA 94102"}
                                                                       appPickerTitle:@"Directions"];
    [self.choosy registerUIElement:self.navigateButton forAction:navigateAction];
    [self.choosy registerUIElement:self.navigateButtonCustom forAction:navigateAction];
    
    
    SBChoosyActionContext *twitterAction = [SBChoosyActionContext contextWithAppType:@"Twitter"
                                                                              action:@"show_profile"
                                                                          parameters:@{ @"profile_screenname" : @"KarlTheFog",
                                                                                        @"callback_url" : @"choosy://"}
                                                                      appPickerTitle:@"Karl the Fog's Timeline"];
    [self.choosy registerUIElement:self.twitterButton forAction:twitterAction];
    [self.choosy registerUIElement:self.twitterButtonCustom forAction:twitterAction];
    
    
    SBChoosyActionContext *emailAction = [SBChoosyActionContext contextWithAppType:@"Email"
                                                                            action:@"Compose"
                                                                        parameters:@{ @"to" : @"choosy@substantial.com",
                                                                                      @"subject" : @"HAI"
                                                                                      }
                                                                    appPickerTitle:@"choosy@substantial.com"];
    [self.choosy registerUIElement:self.emailButton forAction:emailAction];
    [self.choosy registerUIElement:self.emailButtonCustom forAction:emailAction];
    
    [self.choosy registerUIElement:self.bottomView
                      forAction:[SBChoosyActionContext contextWithAppType:@"Browser"
                                                                   action:@"browse_http"
                                                               parameters:@{@"url_no_scheme" : @"www.substantial.com"}]];
    [self.choosy update];
    
    [self setupAppearance];
    
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    if (![reachability isReachable]) {
        [reachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleNetworkChange:) name:kReachabilityChangedNotification object: nil];
    }
}

-(IBAction)switchToDefaultChoosyUI
{
    self.choosy.delegate = nil;
}

- (IBAction)switchToCustomChoosyUI
{
    self.choosy.delegate = self;
}

- (IBAction)showDirections:(UIButton *)sender
{
    [self.choosy handleAction:[SBChoosyActionContext contextWithAppType:@"Maps"
                                                              action:@"directions"
                                                          parameters:@{@"end_address" :
                                                @"25 Taylor St, San Francisco, CA 94102"}]];
}

- (IBAction)showInBrowser
{
    [self.choosy handleAction:[SBChoosyActionContext contextWithAppType:@"Browser" action:@"browse" parameters:@{@"url" : @"http://www.substantial.com"}]];
}

- (void)handleNetworkChange:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable]) {
        [self showOnMap];
        [self.choosy update];
        NSLog(@"Network is now reachable, called update");
    }
}

- (void)setupAppearance
{
    [self showOnMap];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = @"ABOUT";
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"Verdana" size:20];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.navigationItem setTitleView:titleLabel];

}

- (void)showOnMap
{
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder geocodeAddressString:@"25 Taylor St, San Francisco, CA 94102" completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks firstObject];
        
        SFOfficeAnnotation *sfAnnotation = [[SFOfficeAnnotation alloc] initWithCoordinate: placemark.location.coordinate];
        [self.mapView addAnnotation:sfAnnotation];
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude), 1000, 1000)];
    }];
}

#pragma mark SBChoosyDelegate

- (void)showCustomChoosyPickerWithModel:(SBChoosyPickerViewModel *)viewModel
{
    self.pickerViewModel = viewModel;
    
    UIActionSheet *appSheet = [[UIActionSheet alloc] init];
    appSheet.title = self.pickerViewModel.pickerTitleText;
    appSheet.delegate = self;

    for (SBChoosyPickerAppInfo *appInfo in self.pickerViewModel.appTypeInfo.installedApps) {
        [appSheet addButtonWithTitle:appInfo.appName];
    }
    [appSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button title")];
    
    appSheet.cancelButtonIndex = appSheet.numberOfButtons - 1;
    
    [appSheet showInView:self.view];
    
//    SBCustomPickerViewController *customPicker = [[SBCustomPickerViewController alloc] initWithModel:viewModel];
//    self.customAppPicker = customPicker;
//    
//    customPicker.delegate = self;
//    
//    [self presentViewController:customPicker animated:NO completion:nil];
}

#pragma mark SBChoosyPickerDelegate

- (void)didDismissPicker
{
    [self.customAppPicker dismissViewControllerAnimated:YES completion:nil];
    
    [self.choosy didDismissPicker];
}

- (void)didSelectApp:(NSString *)appKey
{
    [self.choosy didSelectApp:appKey];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // see if an app was selected
    if (buttonIndex < [self.pickerViewModel.appTypeInfo.installedApps count]) {
        [self.choosy didSelectApp:((SBChoosyPickerAppInfo *)self.pickerViewModel.appTypeInfo.installedApps[buttonIndex]).appKey];
    } else {
        [self.choosy didDismissPicker];
    }
}

@end

@implementation SFOfficeAnnotation

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self = [super init]) {
        _coordinate = coordinate;
    }
    return self;
}

@end
