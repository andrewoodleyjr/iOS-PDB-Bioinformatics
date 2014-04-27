//
//  ProteinTableViewController.m
//  bio
//
//  Created by Harmon Group on 4/25/14.
//  Copyright (c) 2014 Andre Woodley. All rights reserved.
//

#import "ProteinTableViewController.h"
#import "XMLReader.h"

@interface ProteinTableViewController ()
{
    NSString *path;
    NSArray *paths;
    NSDictionary *xmlDictionary;
    NSFileManager *fileManager;
    atomObject *objectAtom;
    NSMutableArray *tempSearch;
    BOOL searching;
}

@property (strong, nonatomic) NSMutableArray *proteinArray;

@end

@implementation ProteinTableViewController
@synthesize proteinArray;
@synthesize menuSlider;

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
    self.navigationItem.title = self.protein;
    tempSearch = [[NSMutableArray alloc] init];
    proteinArray = [[NSMutableArray alloc] init];
    fileManager = [NSFileManager defaultManager];
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    [self setUpSlider];
    [self setImage];
    [self setXMLToJSONObject];
    [self setTopView];
    self.tableView.allowsMultipleSelection = YES;
    
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    BOOL valid;
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:searchBar.text];
    valid = [alphaNums isSupersetOfSet:inStringSet];
    if (!valid){
        // Not numeric
        [self searchForOccurances:searchBar.text];
    }else{
        [self searchForAmminoAcid:searchBar.text];
    }
    
}

-(void)searchForOccurances:(NSString *)amminoAcid{
    [tempSearch removeAllObjects];
    BOOL found = NO;
    for (NSArray *tempArray in proteinArray) {
        for (atomObject *tempObject in tempArray) {
            if ([tempObject.altLoc isEqualToString:[amminoAcid uppercaseString]]) {
                found = YES;
                [tempSearch addObject:tempArray];
            }
            break;
        }
    }
    if (!found) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Search Results" message:@"Could not find the number of occurrences." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Search Results" message:[NSString stringWithFormat:@"The number of occurrences for %@ is %lu", [amminoAcid uppercaseString], [tempSearch count]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
        searching = YES;
        [self.tableView reloadData];
    }

}

-(void)searchForAmminoAcid:(NSString *)usingSequenceID{
    [tempSearch removeAllObjects];
    BOOL found = NO;
    NSString *tempAlertMessage = @"Could not find the Ammino Acid";
    for (NSArray *tempArray in proteinArray) {
        if (!found) {
            for (atomObject *tempObject in tempArray) {
                if ([tempObject.chainID intValue] == [usingSequenceID intValue] ) {
//                    tempAlertMessage = [NSString stringWithFormat:@"Based on the sequence number %@ this Ammino Acid is %@", usingSequenceID, tempObject.altLoc];
                    found = YES;
                    [tempSearch addObject:tempArray];
                    searching = YES;
                    [self.tableView reloadData];
                }
                break;
            }
        }else{
            break;
        }
    }
    if (!found) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Search Results" message:tempAlertMessage delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

-(void)setUpSlider{
    
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if ([searchText isEqualToString:@""]) {
        searching = NO;
        [self.tableView reloadData];
    }
    
}

-(void)setImage{
    _proteinImage.layer.cornerRadius = 30;
    _proteinImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _proteinImage.layer.borderWidth = 0.5;
    _proteinImage.layer.masksToBounds = YES;
    self.proteinImage.image = [UIImage imageWithContentsOfFile:[[paths objectAtIndex:0] stringByAppendingPathComponent:[self.protein stringByAppendingString:@".jpg"]]];
}

-(void)setXMLToJSONObject{
    NSError *stringError;
    NSString *XMLString = [NSString stringWithContentsOfFile:[[paths objectAtIndex:0] stringByAppendingPathComponent:[self.protein stringByAppendingString:@".xml"]] encoding:NSUTF8StringEncoding error:&stringError];
    if (stringError) {
        // NSLog(@"error %@", stringError);
    }
    
    NSError *parseError = nil;
    xmlDictionary = [XMLReader dictionaryForXMLString:XMLString error:&parseError];
    // NSLog(@"Count Objects for PDBx:atom_siteCategory %lu", (unsigned long)[[[[xmlDictionary objectForKey:@"PDBx:datablock" ] objectForKey:@"PDBx:atom_siteCategory"] objectForKey:@"PDBx:atom_site" ] count]);
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:xmlDictionary
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        // NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        // NSLog(@"%@",jsonString);
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    int currentSeqNum = 0;
    for (int i = 1; i <= [[[[xmlDictionary objectForKey:@"PDBx:datablock" ] objectForKey:@"PDBx:atom_siteCategory"] objectForKey:@"PDBx:atom_site" ] count]; i++) {
        
        NSDictionary *tempObject = [[[[xmlDictionary objectForKey:@"PDBx:datablock" ] objectForKey:@"PDBx:atom_siteCategory"] objectForKey:@"PDBx:atom_site" ] objectAtIndex:i-1];
        
        if ([[[tempObject objectForKey:@"PDBx:group_PDB"] objectForKey:@"text"] isEqualToString:@"ATOM"]) {
            
            if (currentSeqNum == 0) {
                currentSeqNum = [[[tempObject objectForKey:@"PDBx:auth_seq_id"] objectForKey:@"text"] intValue];
            }
            
            objectAtom = [[atomObject alloc] init];
            objectAtom.serial = i;
            objectAtom.name = [[tempObject objectForKey:@"PDBx:auth_atom_id"] objectForKey:@"text"];
            objectAtom.altLoc = [[tempObject objectForKey:@"PDBx:auth_comp_id"] objectForKey:@"text"];
            objectAtom.resName = [[tempObject objectForKey:@"PDBx:auth_asym_id"] objectForKey:@"text"];
            objectAtom.chainID = [[tempObject objectForKey:@"PDBx:auth_seq_id"] objectForKey:@"text"];
            objectAtom.x = [[tempObject objectForKey:@"PDBx:Cartn_x"] objectForKey:@"text"];
            objectAtom.y = [[tempObject objectForKey:@"PDBx:Cartn_y"] objectForKey:@"text"];
            objectAtom.z = [[tempObject objectForKey:@"PDBx:Cartn_z"] objectForKey:@"text"];
            
            // array using the objects...
            if (currentSeqNum == [objectAtom.chainID intValue]) {
                [tempArray addObject:objectAtom];
            }else{
                
                // NSLog(@"Current Temp array is %@", tempArray);
                // dictionary using sequence number
                [proteinArray addObject:tempArray];
                
                // NSLog(@"Total protein array is %@", proteinArray);
                
                // Reset everything
                currentSeqNum = [[[tempObject objectForKey:@"PDBx:auth_seq_id"] objectForKey:@"text"] intValue];
                tempArray = [NSMutableArray new];
                
                // Add to the object
                [tempArray addObject:objectAtom];
            }
        }
    }
    [proteinArray addObject:tempArray];
    
    // NSLog(@"The array %@", proteinArray);
}

-(void)setTopView{
    self.dnaLabel.text = self.protein;
    self.atomNumber.text = [NSString stringWithFormat:@"Number of atoms %lu", (unsigned long)[[[[xmlDictionary objectForKey:@"PDBx:datablock" ] objectForKey:@"PDBx:atom_siteCategory"] objectForKey:@"PDBx:atom_site" ] count]];
    self.aaNumber.text = [NSString stringWithFormat:@"Number of Ammino Acids %lu", [self.proteinArray count]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
    
    if ([selectedIndexPaths count] == 2) {
        NSLog(@"The selected index paths are %@", selectedIndexPaths);
        
        NSIndexPath *indexP1 = [selectedIndexPaths objectAtIndex:0];
        atomObject *object1 = (atomObject *)[[proteinArray objectAtIndex:indexP1.section] objectAtIndex:indexP1.row];
        NSIndexPath *indexP2 = [selectedIndexPaths objectAtIndex:1];
        atomObject *object2 = (atomObject *)[[proteinArray objectAtIndex:indexP2.section] objectAtIndex:indexP2.row];
        
        // Distance formula
        long double distance = sqrtl(powl(([object2.x doubleValue] - [object1.x doubleValue]), 2) + powl(([object2.y doubleValue] - [object1.y doubleValue]), 2) + powl(([object2.z doubleValue] - [object1.z doubleValue]), 2));
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Distance" message:[NSString stringWithFormat:@"The distance between the two is %Lf", distance] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
        
        for (NSIndexPath *indexPaths in selectedIndexPaths) {
            [tableView deselectRowAtIndexPath:indexPaths animated:YES];
        }
        
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    
    if (searching) {
        return [tempSearch count];
    }
    return [self.proteinArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (searching) {
        return [[tempSearch objectAtIndex:section] count];
    }
    return [[self.proteinArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    if (searching) {
        objectAtom = (atomObject *)[[tempSearch objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }else{
    objectAtom = (atomObject *)[[self.proteinArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%d   %@", objectAtom.serial, objectAtom.name ];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"x:%@   y:%@     z:%@", objectAtom.x, objectAtom.y, objectAtom.z];
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50.0)];
    headerView.backgroundColor = [UIColor colorWithRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 310, 20)];
    // NSLog(@"Font names %@", [UIFont familyNames]);
    headerLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
    headerLabel.textColor = [UIColor lightGrayColor];
    
    // NSLog(@"what %@", proteinArray);
    
    if (searching) {
        objectAtom = (atomObject *)[[tempSearch objectAtIndex:section] objectAtIndex:0];
    }else{
        objectAtom = (atomObject *)[[self.proteinArray objectAtIndex:section] objectAtIndex:0];
    }
    
    NSString *chainId = objectAtom.chainID;
    NSString *resName = objectAtom.resName;
    NSString *altLocTxt = objectAtom.altLoc;
    
    headerLabel.text = [NSString stringWithFormat:@"%@   %@    Sequence Number:%@    Atoms:%lu", altLocTxt, resName, chainId, (unsigned long)[[self.proteinArray objectAtIndex:section] count]];
    headerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    headerView.layer.borderWidth = .3;
    [headerView addSubview:headerLabel];
    
    return headerView;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self.view endEditing:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 50.0;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
