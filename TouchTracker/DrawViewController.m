//
//  ViewController.m
//  TouchTracker
//
//  Created by Ernald on 5/20/16.
//  Copyright © 2016 Big Nerd. All rights reserved.
//

#import "DrawViewController.h"
#import "DrawView.h"

@interface DrawViewController ()

@end

@implementation DrawViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView
{
    self.view = [[DrawView alloc] initWithFrame:CGRectZero];
}

@end
