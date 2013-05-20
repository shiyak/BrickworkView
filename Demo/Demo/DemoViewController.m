//
//  DemoViewController.m
//  Demo
//
//  Created by Hirohisa Kawasaki on 13/04/17.
//  Copyright (c) 2013年 Hirohisa Kawasaki. All rights reserved.
//

#import "DemoViewController.h"
#import "BrickworkView.h"

@interface DemoViewController () <BrickworkViewDataSource, BrickworkViewDelegate>
@property (nonatomic, strong) BrickworkView *brickworkView;
@property (nonatomic, strong) NSMutableArray *list;
@end

@implementation DemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.list = @[@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",
                  @"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z"].mutableCopy;
    self.view.backgroundColor = [UIColor grayColor];
    self.brickworkView.padding = 10.;
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 50)];
    headerLabel.text = @"HEADER";
    headerLabel.textAlignment = UITextAlignmentCenter;
    self.brickworkView.headerView = headerLabel;
    [self.view addSubview:self.brickworkView];
    self.brickworkView.brickDataSource = self;
    self.brickworkView.brickDelegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - setter/getter
- (BrickworkView *)brickworkView
{
    if (_brickworkView == nil) {
        _brickworkView = [[BrickworkView alloc]initWithFrame:self.view.bounds];
    }
    return _brickworkView;
}

- (CGFloat)brickworkView:(BrickworkView *)brickworkView heightForCellAtIndex:(NSInteger)index
{
    switch (index%3) {
        case 0: {
            return 100.;
        }
            break;
        case 1: {
            return 50.;
        }
            break;
        case 2: {
            return 70.;
        }
            break;
        default:
            break;
    }
    return 100.;
}

- (NSInteger)numberOfColumnsInBrickworkView:(BrickworkView *)brickworkView
{
    return 3;
}


- (NSInteger)numberOfCellsInBrickworkView:(BrickworkView *)brickworkView
{
    return [self.list count];
}

- (BrickworkViewCell *)brickworkView:(BrickworkView *)brickworkView cellAtIndex:(NSInteger)index
{
    static NSString *CellIdentifier = @"Cell";
	BrickworkViewCell *cell = [brickworkView dequeueReusableCellWithIdentifier:CellIdentifier];

	if(cell == nil)	{
        cell  = [[BrickworkViewCell alloc] initWithReuseIdentifier:CellIdentifier];
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
        label.tag = 1001;
        [cell addSubview:label];
	}

    UILabel *label = (UILabel *)[cell viewWithTag:1001];
    label.frame = CGRectMake(0, 0, brickworkView.widthOfCell, [brickworkView.brickDelegate brickworkView:brickworkView heightForCellAtIndex:index]);
    label.text = [self.list objectAtIndex:index];
    label.textAlignment = UITextAlignmentCenter;

	return cell;
}

#pragma mark -
- (void)brickworkView:(BrickworkView *)brickworkView didSelect:(BrickworkViewCell *)cell AtIndex:(int)index
{
    LOG(@"index %d", index);
}

- (void)brickworkView:(BrickworkView *)brickworkView didLongPress:(BrickworkViewCell *)cell AtIndex:(NSInteger)index
{
    LOG(@"index %d", index);
    [self.list removeObjectAtIndex:index];
    [brickworkView reloadData];
}

- (void)brickworkView:(BrickworkView *)brickworkView didScrollBelowBottomWithOffset:(CGPoint)offset
{
    [self.list addObjectsFromArray:@[@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",@"k",@"l",@"m",
     @"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z"]];
    [brickworkView reloadData];
}
@end
