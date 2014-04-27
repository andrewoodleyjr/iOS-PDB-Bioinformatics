//
//  ProteinTableViewController.h
//  bio
//
//  Created by Harmon Group on 4/25/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "atomObject.h"
#import "SWRevealViewController.h"

@interface ProteinTableViewController : UITableViewController<UIPopoverControllerDelegate, SWRevealViewControllerDelegate, UISearchBarDelegate>
{
    IBOutlet UIViewController *popOverView;
}
@property (strong, nonatomic) NSString *protein;
@property (strong, nonatomic) IBOutlet UIImageView *proteinImage;
@property (strong, nonatomic) IBOutlet UILabel *dnaLabel;
@property (strong, nonatomic) IBOutlet UILabel *atomNumber;
@property (strong, nonatomic) IBOutlet UILabel *aaNumber;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *menuSlider;
@property (strong, nonatomic) IBOutlet UISearchBar *theSearchBar;

@end
