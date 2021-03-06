//
//  TableViewController.h
//  bio
//
//  Created by Harmon Group on 4/15/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQLiteDatabase.h"
#import "AFHTTPRequestOperation.h"
#import "ProteinTableViewController.h"

@interface TableViewController : UITableViewController<UISearchBarDelegate, UISearchDisplayDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate, NSURLConnectionDownloadDelegate>
{
    
    NSMutableArray *databaseArray;
    NSArray *searchResults;
    NSTimer *searchDelayer;
    NSString *searchedText;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;


@end
