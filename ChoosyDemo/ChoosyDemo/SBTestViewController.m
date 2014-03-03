//
//  SBTestViewController.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 1/31/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBTestViewController.h"
#import "SBChoosy.h"
#import "SBChoosyActionContext.h"
#import "Reachability.h"
@import MapKit;

@interface SBTestViewController ()

@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *showSubstantialProfile;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *navigateButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *browserButton;

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
    [self.choosy registerUIElement:self.navigateButton
                      forAction:[SBChoosyActionContext contextWithAppType:@"Maps"
                                                                   action:@"directions"
                                                               parameters:@{@"end_address" : @"25 Taylor St, San Francisco, CA 94102"}]];
    
    [self.choosy registerUIElement:self.showSubstantialProfile
                      forAction:[SBChoosyActionContext contextWithAppType:@"Twitter"
                                                                   action:@"show_profile"
                                                               parameters:@{ @"profile_screenname" : @"KarlTheFog",
                                                                             @"callback_url" : @"choosy://"}
                                                           appPickerTitle:@"Karl the Fog's Timeline"]];
    
    [self.choosy registerUIElement:self.emailButton
                      forAction:[SBChoosyActionContext contextWithAppType:@"Email"
                                                                   action:@"Compose"
                                                               parameters:@{ @"to" : @"choosy@substantial.com",
                                                                                                        @"subject" : @"HAI"
                                                                                                        }
                                                           appPickerTitle:@"choosy@substantial.com"]];
    
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

//- (IBAction)showDirections:(UIButton *)sender
//{
//    NSString *destination = [@"25 Taylor St, San Francisco, CA 94102"
//                             stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    
//    NSString *urlString = [@"http://maps.apple.com/?q=&daddr="
//                           stringByAppendingString:destination];
//    
//    NSURL *url = [NSURL URLWithString:urlString];
//    
//    [[UIApplication sharedApplication] openURL:url];
//}

- (IBAction)showDirections:(UIButton *)sender
{
    
    [self.choosy handleAction:[SBChoosyActionContext contextWithAppType:@"Twitter"
                                                              action:@"show_profile"
                                                          parameters:@{ @"profile_screenname" : @"KarlTheFog",
                                                                             @"callback_url" : @"choosy://"}
                                                      appPickerTitle:@"Karl the Fog's Timeline"]];
    
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
