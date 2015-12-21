//
//  INSOExportOptionsTableViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/18/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOExportOptionsTableViewController.h"

typedef NS_ENUM(NSUInteger, INSOExportOptionsIndex) {
    INSOExportOptionsIndexEmail,
    INSOExportOptionsIndexMaxPreps
};

@interface INSOExportOptionsTableViewController ()

@end

@implementation INSOExportOptionsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.alwaysBounceVertical = NO; 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect the row
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    // Notify the delegate
    switch (indexPath.row) {
        case INSOExportOptionsIndexEmail:
            [self.delegate didSelectEmailStats];
            break;
        case INSOExportOptionsIndexMaxPreps:
            [self.delegate didSelectMaxPrepsExport];
            break;
        default:
            break;
    }
}

@end
