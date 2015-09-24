//
//  INSOGameCollectionViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOGameCollectionViewController.h"

@interface INSOGameCollectionViewController () <UICollectionViewDelegateFlowLayout>

@end

@implementation INSOGameCollectionViewController

static NSString * const reuseIdentifier = @"GameCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register cell classes
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
    CGSize size = flowLayout.itemSize;
    size.width = self.view.frame.size.width;
    size.width -= (flowLayout.sectionInset.left + flowLayout.sectionInset.right);
    return size;
}

@end
