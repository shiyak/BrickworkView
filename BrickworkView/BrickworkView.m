//
//  BrickworkView.m
//  BrickworkView
//
//  Created by Hirohisa Kawasaki on 13/04/17.
//  Copyright (c) 2013年 Hirohisa Kawasaki. All rights reserved.
//

#import "BrickworkView.h"


@interface NSArray (BrickworkView)
- (NSInteger)compareLeastIndex;
- (NSInteger)compareGreatestIndex;
@end

@implementation NSArray (BrickworkView)
- (NSInteger)compareLeastIndex
{
    id benchmark = nil;
    NSInteger index = 0;
    for (NSInteger i=0; i<[self count]; i++) {
        if (!benchmark) benchmark = [self objectAtIndex:i];

        if (floor([[self objectAtIndex:i] floatValue]) < floor([benchmark floatValue])) {
            benchmark = [self objectAtIndex:i];
            index = i;
        }
    }
    return index;
}

- (NSInteger)compareGreatestIndex
{
    id benchmark = nil;
    NSInteger index = 0;
    for (NSInteger i=0; i<[self count]; i++) {
        if (!benchmark) benchmark = [self objectAtIndex:i];

        if (floor([[self objectAtIndex:i] floatValue]) > floor([benchmark floatValue])) {
            benchmark = [self objectAtIndex:i];
            index = i;
        }
    }
    return index;
}
@end

@interface BFIndexPath : NSObject
@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) NSUInteger column;
@property (nonatomic, readonly) CGFloat height;
+ (id)indexPathWithIndex:(NSUInteger)index column:(NSInteger)column height:(CGFloat)height;
@end

@implementation BFIndexPath
+ (id)indexPathWithIndex:(NSUInteger)index column:(NSInteger)column height:(CGFloat)height
{
    return [[self alloc]initWithIndex:index column:column height:height];
}

- (id)initWithIndex:(NSUInteger)index column:(NSInteger)column height:(CGFloat)height
{
    self = [super init];
    if (self) {
        _index = index;
        _height = height;
        _column = column;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<BFIndexPath index:%d, column:%d, height:%.1f>", self.index, self.column, self.height];
}
@end

@interface BrickworkViewCell () {
    @private
    NSNumber *_number;
}
@property (nonatomic) NSInteger index;
@property (nonatomic) NSString *reuseIdentifier;
@property (nonatomic) BOOL touching;
@end

@implementation BrickworkViewCell
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super init]) {
		self.reuseIdentifier = reuseIdentifier;
        [self setup];
	}
	return self;
}

#pragma mark - setter/getter
- (void)setIndex:(NSInteger)index
{
    _number = [NSNumber numberWithInteger:index];
}

- (NSInteger)index
{
    if (_number != nil) {
        return [_number integerValue];
    }
    return NSNotFound;
}

#pragma mark -
- (void)setup
{
    self.touching = NO;
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(handleLongPress:)];
    [self addGestureRecognizer:longPressGesture];
    UITapGestureRecognizer *tapPressGesture = [[UITapGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapPressGesture];
}

- (void)handleTap:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tapCell"
                                                        object:self
                                                      userInfo:nil];
}

- (void)handleLongPress:(id)sender
{
    if (self.touching) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"longpressCell"
                                                            object:self
                                                          userInfo:nil];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touching = YES;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touching = NO;
}

- (void)dealloc
{
    _number = nil;
    self.reuseIdentifier = nil;
}
@end

static CGFloat const kLoadingViewHeight = 44.;

@interface BrickworkView () <UIScrollViewDelegate>
@property(nonatomic) BOOL loading;

@property (nonatomic, readonly) NSInteger numberOfColumns;
@property (nonatomic) NSInteger numberOfCells;
@property (nonatomic, readonly) CGPoint lazyOffset;
@property (nonatomic, strong) NSMutableArray *heightIndices;
@property (nonatomic, strong) NSMutableArray *visibleCells;
@property (nonatomic, strong) NSMutableDictionary *reusableCells;
@end

@implementation BrickworkView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.clipsToBounds = NO;
		self.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tapCell:)
                                                     name:@"tapCell"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(longPressCell:)
                                                     name:@"longpressCell"
                                                   object:nil];
        self.loading = NO;
        [self initialize];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"tapCell"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"longpressCell"
                                                  object:nil];
    self.heightIndices = nil;
    self.visibleCells = nil;
    self.reusableCells = nil;
    self.brickDataSource = nil;
    self.brickDelegate = nil;
}

#pragma mark -
- (void)refreshData
{
    for (id cell in self.visibleCells) {
        [self recycleCellIntoReusableQueue:(BrickworkViewCell *)cell];
        [cell removeFromSuperview];
    }
    self.visibleCells = @[].mutableCopy;
    [self reloadData];
}

- (void)reloadData
{
    self.loading = NO;
    [self initialize];
}

#pragma mark - setter/getter
- (void)setBrickDataSource:(id<BrickworkViewDataSource>)brickDataSource
{
    _brickDataSource = brickDataSource;
    if (_brickDataSource != nil && _brickDelegate != nil) {
        [self initialize];
    }
}

- (void)setBrickDelegate:(id<BrickworkViewDelegate>)brickDelegate
{
    _brickDelegate = brickDelegate;
    if (_brickDataSource != nil && _brickDelegate != nil) {
        [self initialize];
    }
}

- (NSInteger)numberOfColumns
{
    return [self.brickDataSource numberOfColumnsInBrickworkView:self];
}

- (NSMutableArray *)visibleCells
{
    if (_visibleCells == nil) {
        _visibleCells = @[].mutableCopy;
    }
    return _visibleCells;
}

- (NSMutableDictionary *)reusableCells
{
    if (_reusableCells == nil) {
        _reusableCells = @{}.mutableCopy;
    }
    return _reusableCells;
}

-(CGFloat)widthOfCell
{
    CGFloat width = CGRectGetWidth(self.bounds);
    width -= self.padding * (self.numberOfColumns+1);
    return width/(self.numberOfColumns);
}

#pragma mark - NSNotification
- (void)tapCell:(NSNotification *)notification
{
    if ([self.brickDelegate respondsToSelector:@selector(brickworkView:didSelect:AtIndex:)]) {
        BrickworkViewCell *cell = (BrickworkViewCell *)[notification object];
        [self.brickDelegate brickworkView:self didSelect:cell AtIndex:cell.index];
    }
}

- (void)longPressCell:(NSNotification *)notification
{
    if ([self.brickDelegate respondsToSelector:@selector(brickworkView:didLongPress:AtIndex:)]) {
        BrickworkViewCell *cell = (BrickworkViewCell *)[notification object];
        [self.brickDelegate brickworkView:self didLongPress:cell AtIndex:cell.index];
    }
}

#pragma mark - reusable
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    if (!identifier || identifier == 0 ) return nil;
    if ([self.reusableCells objectForKey:identifier] != nil &&
        [[self.reusableCells objectForKey:identifier] count] > 0) {
        id cell = [[self.reusableCells objectForKey:identifier] lastObject];
        [[self.reusableCells objectForKey:identifier] removeLastObject];
        return cell;
    }
    return nil;
}

- (void)recycleCellIntoReusableQueue:(BrickworkViewCell *)cell
{
    if (![self.reusableCells objectForKey:cell.reuseIdentifier]) {
        [self.reusableCells setObject:@[].mutableCopy forKey:cell.reuseIdentifier];
    }
    [[self.reusableCells objectForKey:cell.reuseIdentifier] addObject:cell];
}

#pragma mark -
- (void)initialize
{
    self.numberOfCells = [self.brickDataSource numberOfCellsInBrickworkView:self];
    self.heightIndices = @[].mutableCopy;
    for (int i=0; i<[self.brickDataSource numberOfColumnsInBrickworkView:self]; i++) {
        [self.heightIndices addObject:@[].mutableCopy];
    }
    [self adjustContent];
    [self setup];
    [self renderCells];
}

#pragma mark - logic
- (void)adjustContent
{
    NSUInteger lowerColumn = 0;
    NSMutableArray *lastHeights = @[].mutableCopy;
    CGFloat offsetHeight = self.padding;
    if (self.headerView != nil) {
        offsetHeight += CGRectGetHeight(self.headerView.bounds)+self.padding;
    }
    for (int i=0; i<[self.brickDataSource numberOfColumnsInBrickworkView:self]; i++) {
        [lastHeights addObject:[NSNumber numberWithFloat:offsetHeight]];
    }

    for (int index = 0; index< self.numberOfCells; index++) {
        lowerColumn = [lastHeights compareLeastIndex];
        CGFloat height = [[lastHeights objectAtIndex:lowerColumn] floatValue];
        BFIndexPath *indexPath = [BFIndexPath indexPathWithIndex:index column:lowerColumn height:height];
        [[self.heightIndices objectAtIndex:lowerColumn] addObject:indexPath];
        height += ([self.brickDelegate brickworkView:self heightForCellAtIndex:index] + self.padding);

        [lastHeights setObject:[NSNumber numberWithFloat:height] atIndexedSubscript:lowerColumn];
    }

    CGFloat contentHeight = 0.;
    if ([lastHeights count] > 0) {
        contentHeight = [[lastHeights objectAtIndex:[lastHeights compareGreatestIndex]] floatValue];
    }

    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight + kLoadingViewHeight);
}

- (void)setup
{
    if (self.headerView != nil) {
        CGFloat height = CGRectGetHeight(self.headerView.bounds);
        self.headerView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, (height/2)+self.padding);
        [self addSubview:self.headerView];
    }
}

- (void)renderCells
{
    CGSize limit = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)*3);
    NSMutableArray *indexPaths = [self getBFIndexPaths:self.lazyOffset limit:limit].mutableCopy;

    NSMutableArray *cells = @[].mutableCopy;
    // remove not visibled cells
    for (BrickworkViewCell *cell in self.visibleCells) {
        BOOL include = NO;
        NSInteger index = 0;
        for (int i=0; i<[indexPaths count]; i++) {
            BFIndexPath *indexPath = [indexPaths objectAtIndex:i];
            if (indexPath.index == cell.index) {
                include = YES;
                index = i;
            }
        }
        if (!include) {
            [self recycleCellIntoReusableQueue:(BrickworkViewCell *)cell];
            [cell removeFromSuperview];
        } else {
            [cells addObject:cell];
            [indexPaths removeObjectAtIndex:index];
        }
    }
    // add cells to visibled
    [cells addObjectsFromArray:[self getCellsWithIndexPaths:indexPaths]];

    self.visibleCells = cells.mutableCopy;
    for (BrickworkViewCell *cell in self.visibleCells) {
        if (![cell isDescendantOfView:self]) {
            [self addSubview:cell];
        }
    }
}

- (CGPoint)lazyOffset
{
    CGFloat x = self.contentOffset.x - CGRectGetWidth(self.bounds);
    CGFloat y = self.contentOffset.y - CGRectGetHeight(self.bounds);
    return CGPointMake((x>0.)?x:0., (y>0.)?y:0.);
}

- (NSArray *)getBFIndexPaths:(CGPoint)offset limit:(CGSize)limit
{
    NSMutableArray *indexPaths = @[].mutableCopy;
    for (int column=0; column<[self.heightIndices count]; column++) {
        NSArray *list = [self.heightIndices objectAtIndex:column];
        for (int i=0; i<[list count]; i++) {
            BFIndexPath *indexPath = [list objectAtIndex:i];
            if (offset.y <= indexPath.height && indexPath.height <= offset.y + limit.height) {
                [indexPaths addObject:indexPath];
            } else if (indexPath.height > offset.y + limit.height) {
                break;
            }
        }
    }
    return indexPaths.copy;
}

- (NSArray *)getCellsWithIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *cells = @[].mutableCopy;
    for (BFIndexPath *indexPath in indexPaths) {
        [cells addObject:[self cellAtIndexPath:indexPath]];
    }
    return cells.copy;
}

- (BrickworkViewCell *)cellAtIndexPath:(BFIndexPath *)indexPath
{
    BrickworkViewCell *cell = [self.brickDataSource brickworkView:self cellAtIndex:indexPath.index];
    cell.index = indexPath.index;

    CGFloat height = [self.brickDelegate brickworkView:self heightForCellAtIndex:indexPath.index];

    CGFloat x = indexPath.column*self.widthOfCell + self.padding*(indexPath.column+1);
    CGFloat y = indexPath.height;
    cell.frame = CGRectMake(x, y , self.widthOfCell, height);
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self renderCells];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    CGFloat bottomEdge = scrollView.contentOffset.y + CGRectGetHeight(scrollView.frame);
    if (bottomEdge >= floor(scrollView.contentSize.height)) {
        [self scrollBelowBottom];
    }
}

- (void)scrollBelowBottom
{
    if (self.loading) return;
    self.loading = YES;
    if ([self.brickDelegate respondsToSelector:@selector(brickworkView:didScrollBelowBottomWithOffset:)]) {
        [self.brickDelegate brickworkView:self didScrollBelowBottomWithOffset:self.contentOffset];
    }
}
@end
