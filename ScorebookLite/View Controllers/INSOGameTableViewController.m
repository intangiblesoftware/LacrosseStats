//
//  INSOGameTableViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOGameTableViewController.h"

static NSString* const INSOGameCellIdentifier = @"GameCell";

@interface INSOGameTableViewController ()

@end

@implementation INSOGameTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameCellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 189.0;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
