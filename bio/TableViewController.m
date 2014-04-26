//
//  TableViewController.m
//  bio
//
//  Created by Harmon Group on 4/15/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()
{
    UIAlertView *alertView;
    NSFileManager *fileManager;
    NSMutableData *_responseData;
}
@end

@implementation TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    databaseArray = [[NSMutableArray alloc] init];
    searchResults = [[NSArray alloc] init];
}


-(void)viewWillAppear:(BOOL)animated
{
    
    databaseArray = [[SQLiteDatabase database] getDNAFromDatabase:@"SELECT dna_name FROM dna"];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [searchResults count];
    }
    return databaseArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"rowCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [searchResults objectAtIndex:indexPath.row];
    } else {
        cell.textLabel.text = [databaseArray objectAtIndex:indexPath.row];
    }
    
    return cell;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}



- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    // NSLog(@"Searching...");
    searchedText = searchBar.text;
    NSString *urlString = [NSString stringWithFormat:@"http://www.pdb.org/pdb/files/%@.xml", [searchBar.text uppercaseString]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] delegate:self];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    // NSLog(@"Recieved data");
    
    [_responseData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    alertView = [[UIAlertView alloc] initWithTitle:@"Whoa" message:[NSString stringWithFormat:@"%@ could not be found.", searchedText] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    [alertView show];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    
    // NSLog(@"Did Finish...");
    
    NSString *xmlDataToString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    
    // Verify XML
    // If good tell user they downloaded the file and download the image...
    // Then save the name of the protein to the database...
    // If bad, it was not found...
    if ([self containsString:xmlDataToString]) {
        // Save file
        NSString *fileName = [NSString stringWithFormat:@"%@.xml", [searchedText uppercaseString]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
        [_responseData writeToFile:path atomically:YES];
        
        NSString *urlString = [NSString stringWithFormat:@"http://www.rcsb.org/pdb/images/%@_bio_r_500.jpg", [searchedText lowercaseString]];
        NSData *theImage = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        fileName = [NSString stringWithFormat:@"%@.jpg", [searchedText uppercaseString]];
        path = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
        [theImage writeToFile:path atomically:YES];
        
        BOOL okay = [[SQLiteDatabase database] noReturnDNADatabaseQuery:[NSString stringWithFormat:@"INSERT INTO dna (dna_name) VALUES('%@')", [searchedText uppercaseString]]];
        if (okay) {
            alertView = [[UIAlertView alloc] initWithTitle:@"Yes" message:@"The protein was saved." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [databaseArray addObject:[searchedText uppercaseString]];
            [self.tableView reloadData];
            [self.searchDisplayController setActive:NO animated:YES];
        }else{
            alertView = [[UIAlertView alloc] initWithTitle:@"Whoa" message:@"The protein was not saved properly." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        }
        
        
    }else{
        alertView = [[UIAlertView alloc] initWithTitle:@"Whoa" message:[NSString stringWithFormat:@"%@ could not be found.", searchedText] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        
    }
    [alertView show];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        // NSLog(@"Deleting protein...");
        // Remove it from the sql database
        // Delete the file (xml and image)
        // remove it from the array
        // update the tableview
        BOOL okay = [[SQLiteDatabase database] noReturnDNADatabaseQuery:[NSString stringWithFormat:@"DELETE FROM dna WHERE dna_name = '%@'", [databaseArray objectAtIndex:indexPath.row]]];
        if (okay) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            NSString *fileName = [NSString stringWithFormat:@"%@.xml", [databaseArray objectAtIndex:indexPath.row]];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath:path error:&error];
            fileName = [NSString stringWithFormat:@"%@.jpg", [databaseArray objectAtIndex:indexPath.row]];
            path = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath:path error:&error];
            alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"The protein was deleted." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [databaseArray removeObjectAtIndex:indexPath.row];
            [self.tableView reloadData];

        }else{
            alertView = [[UIAlertView alloc] initWithTitle:@"Whoa" message:@"An error occured..." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        }
        [alertView show];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UITableViewCell *cell = (UITableViewCell *)sender;
    // NSLog(@"cell title %@", cell.textLabel.text);
    
    ProteinTableViewController *pViewController = (ProteinTableViewController *)segue.destinationViewController;
    pViewController.protein = cell.textLabel.text;
    
    
}

- (BOOL) containsString: (NSString*) string
{
    NSRange range = [string rangeOfString :@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];
    BOOL found = ( range.location != NSNotFound );
    return found;
}

@end
