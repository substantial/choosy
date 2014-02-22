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
#import "SBChoosyRegister.h"

@interface SBTestViewController ()

@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UILabel *showSubstantialProfile;
@property (weak, nonatomic) IBOutlet UILabel *openTwitter;

@end

@implementation SBTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [SBChoosy registerUIElement:self.openTwitter forAction:[SBChoosyActionContext contextWithAppType:@"Twitter"]];
    
    [SBChoosy registerUIElement:self.showSubstantialProfile
                      forAction:[SBChoosyActionContext contextWithAppType:@"Twitter"
                                                                   action:@"show_profile"
                                                               parameters:@{ @"profile_screenname" : @"Substantial",
                                                                             @"callback_url" : @"http://www.substantial.com//"}]];
    
    [SBChoosy registerUIElement:self.emailButton forAction:[SBChoosyActionContext contextWithAppType:@"Email"
                                                                                              action:@"Compose" parameters:@{ @"from" : @"choosy@substantial.com" }
                                                                                      appPickerTitle:@"choosy@substantial.com"]];
    [SBChoosy update];
}

- (void)viewDidAppear:(BOOL)animated
{
    [SBChoosy update];
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
