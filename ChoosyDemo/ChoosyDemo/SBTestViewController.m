//
//  SBTestViewController.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 1/31/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBTestViewController.h"
#import "SBChoosyRegister.h"
#import "SBChoosyActionContext.h"

@interface SBTestViewController ()

@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UILabel *twitterLinkLabel;

@property (nonatomic) SBChoosyRegister *choosyRegister;

@end

@implementation SBTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // register label with Choosy
    self.choosyRegister = [SBChoosyRegister new];
    [self.choosyRegister registerUIElement:self.twitterLinkLabel forAction:[SBChoosyActionContext contextWithAppType:@"Twitter"]];
    
    [self.choosyRegister registerUIElement:self.emailButton forAction:[SBChoosyActionContext contextWithAppType:@"Email"
                                                                                              action:@"Compose" parameters:@{ @"from:" : @"your_mom@substantial.com" }]];
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
