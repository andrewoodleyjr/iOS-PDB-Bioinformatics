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
}

@property (strong, nonatomic) NSMutableArray *proteinArray;

@end

@implementation ProteinTableViewController
@synthesize proteinArray;

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
    proteinArray = [[NSMutableArray alloc] init];
    fileManager = [NSFileManager defaultManager];
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSHashTable *hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsCopyIn];
    [hashTable addObject:@"foo"];
    [hashTable addObject:@"bar"];
    [hashTable addObject:@42];
    [hashTable removeObject:@"bar"];
    [hashTable addObject:self.protein];
    // NSLog(@"Members: %@", [hashTable allObjects]);
    
    [self setImage];
    [self setXMLToJSONObject];
    [self setTopView];
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
    self.aaNumber.text = [NSString stringWithFormat:@"Number of Ammino Acids %lu", [self.proteinArray count]];
    return [self.proteinArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.proteinArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = @"hello world";
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
    
    objectAtom = (atomObject *)[[self.proteinArray objectAtIndex:section] objectAtIndex:0];
    NSString *chainId = objectAtom.chainID;
    NSString *resName = objectAtom.resName;
    NSString *altLocTxt = objectAtom.altLoc;
    
    headerLabel.text = [NSString stringWithFormat:@"%@   %@    %@    Atoms:%lu", altLocTxt, resName, chainId, (unsigned long)[[self.proteinArray objectAtIndex:section] count]];
    headerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    headerView.layer.borderWidth = .3;
    [headerView addSubview:headerLabel];
    return headerView;
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
