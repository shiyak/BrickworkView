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
        if (!benchmark) benchmark = self[i];

        if (floor([self[i] floatValue]) < floor([benchmark floatValue])) {
            benchmark = self[i];
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
        if (!benchmark) benchmark = self[i];

        if (floor([self[i] floatValue]) > floor([benchmark floatValue])) {
            benchmark = self[i];
            index = i;
        }
    }
    return index;
}
@end

@interface BWIndexPath : NSObject
@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) NSUInteger column;
@property (nonatomic, readonly) CGFloat height;
+ (id)indexPathWithIndex:(NSUInteger)index column:(NSInteger)column height:(CGFloat)height;
@end

@implementation BWIndexPath
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
    return [NSString stringWithFormat:@"<BWIndexPath index:%d, column:%d, height:%.1f>", self.index, self.column, self.height];
}
@end

@protocol BrickworkViewCellDelegate <NSObject>
- (void)didLongPress:(BrickworkViewCell *)cell sender:(id)sender;
- (void)didTap:(BrickworkViewCell *)cell sender:(id)sender;
@end

@interface BrickworkViewCell () {
    @private
    NSNumber *_number;
}
@property (nonatomic, assign) id<BrickworkViewCellDelegate> delegate;
@property (nonatomic) NSInteger bwIndex;
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
- (void)setBwIndex:(NSInteger)bwIndex
{
    _number = @(bwIndex);
}

- (NSInteger)bwIndex
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
}

- (void)handleLongPress:(UIGestureRecognizer *)gesture
{
    if (self.touching) {
        [self.delegate didLongPress:self sender:nil];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.touching = YES;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.touching = NO;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (self.touching) {
        self.touching = NO;
        [self.delegate didTap:self sender:nil];
    }
}

- (void)dealloc
{
    _number = nil;
    self.reuseIdentifier = nil;
}
@end

static CGFloat const kLoadingViewHeight = 44.;

@interface BrickworkView () <UIScrollViewDelegate, BrickworkViewCellDelegate>
@property(nonatomic) BOOL loading;

@property (nonatomic, readonly) NSInteger numberOfColumns;
@property (nonatomic) NSInteger numberOfCells;
@property (nonatomic, readonly) CGPoint lazyOffset;
@property (nonatomic, strong) NSMutableArray *heightIndexes;
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
        self.loading = NO;
        [self initialize];
    }
    return self;
}

- (void)dealloc
{
    _heightIndexes = nil;
    _visibleCells = nil;
    _reusableCells = nil;
    _brickDataSource = nil;
    _brickDelegate = nil;
}

#pragma mark -
- (void)reloadData
{
    for (id cell in self.visibleCells) {
        [self recycleCellIntoReusableQueue:cell];
        [cell removeFromSuperview];
    }
    self.visibleCells = @[].mutableCopy;
    [self updateData];
}

- (void)updateData
{
    self.loading = NO;
    [self initialize];
}

#pragma mark - setter/getter
- (void)setBrickDataSource:(id<BrickworkViewDataSource>)brickDataSource
{
    _brickDataSource = brickDataSource;
    [self initialize];
}

- (void)setBrickDelegate:(id<BrickworkViewDelegate>)brickDelegate
{
    _brickDelegate = brickDelegate;
    [self initialize];
}

- (void)setHeaderView:(UIView *)headerView
{
    _headerView = headerView;
    [self initialize];
}

- (void)setFooterView:(UIView *)footerView
{
    _footerView = footerView;
    [self initialize];
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
- (void)didLongPress:(BrickworkViewCell *)cell sender:(id)sender
{
    if ([self.brickDelegate respondsToSelector:@selector(brickworkView:didLongPress:AtIndex:)]) {
        [self.brickDelegate brickworkView:self didLongPress:cell AtIndex:cell.bwIndex];
    }
}

- (void)didTap:(BrickworkViewCell *)cell sender:(id)sender
{
    if ([self.brickDelegate respondsToSelector:@selector(brickworkView:didSelect:AtIndex:)]) {
        [self.brickDelegate brickworkView:self didSelect:cell AtIndex:cell.bwIndex];
    }
}

#pragma mark - reusable
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    if (identifier &&
        self.reusableCells &&
        [self.reusableCells objectForKey:identifier] &&
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
- (BOOL)validateToInitialize
{
    return _brickDataSource && _brickDelegate;
}

- (void)initialize
{
    if (![self validateToInitialize]) {
        return;
    }

    self.numberOfCells = [self.brickDataSource numberOfCellsInBrickworkView:self];
    self.heightIndexes = @[].mutableCopy;
    for (int i=0; i<[self.brickDataSource numberOfColumnsInBrickworkView:self]; i++) {
        [self.heightIndexes addObject:@[].mutableCopy];
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
    if (self.headerView) {
        offsetHeight += CGRectGetHeight(self.headerView.bounds)+self.padding;
    }
    for (int i=0; i<[self.brickDataSource numberOfColumnsInBrickworkView:self]; i++) {
        [lastHeights addObject:[NSNumber numberWithFloat:offsetHeight]];
    }

    for (int index = 0; index< self.numberOfCells; index++) {
        lowerColumn = [lastHeights compareLeastIndex];
        CGFloat height = [lastHeights[lowerColumn] floatValue];
        BWIndexPath *indexPath = [BWIndexPath indexPathWithIndex:index column:lowerColumn height:height];
        [self.heightIndexes[lowerColumn] addObject:indexPath];
        height += ([self.brickDelegate brickworkView:self heightForCellAtIndex:index] + self.padding);

        [lastHeights setObject:@(height) atIndexedSubscript:lowerColumn];
    }

    CGFloat contentHeight = 0.;
    if ([lastHeights count] > 0) {
        contentHeight = [lastHeights[[lastHeights compareGreatestIndex]] floatValue];
    }
    if (self.footerView) {
        contentHeight += CGRectGetHeight(self.footerView.bounds)+self.padding;
    }
    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight + kLoadingViewHeight);
}

- (void)setup
{
    if (self.headerView) {
        CGFloat height = CGRectGetHeight(self.headerView.bounds);
        self.headerView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, (height/2)+self.padding);
        [self addSubview:self.headerView];
    }
    if (self.footerView) {
        CGFloat height = CGRectGetHeight(self.footerView.bounds);
        self.footerView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, self.contentSize.height-height/2);
        [self addSubview:self.footerView];
    }
}

- (void)renderCells
{
    CGSize limit = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)*3);
    NSMutableArray *indexPaths = [self getBWIndexPaths:self.lazyOffset limit:limit].mutableCopy;

    NSMutableArray *cells = @[].mutableCopy;
    // remove not visibled cells
    for (BrickworkViewCell *cell in self.visibleCells) {
        BOOL include = NO;
        NSInteger index = 0;
        for (int i=0; i<[indexPaths count]; i++) {
            BWIndexPath *indexPath = indexPaths[i];
            if (indexPath.index == cell.bwIndex) {
                include = YES;
                index = i;
            }
        }
        if (!include) {
            [self recycleCellIntoReusableQueue:cell];
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
        cell.delegate = self;
        if (![cell isDescendantOfView:self]) {
            [self addSubview:cell];
            [cell layoutSubviews];
        }
    }
}

- (CGPoint)lazyOffset
{
    CGFloat x = self.contentOffset.x - CGRectGetWidth(self.bounds);
    CGFloat y = self.contentOffset.y - CGRectGetHeight(self.bounds);
    return CGPointMake((x>0.)?x:0., (y>0.)?y:0.);
}

- (NSArray *)getBWIndexPaths:(CGPoint)offset limit:(CGSize)limit
{
    NSMutableArray *indexPaths = @[].mutableCopy;
    for (int column=0; column<[self.heightIndexes count]; column++) {
        NSArray *list = self.heightIndexes[column];
        for (int i=0; i<[list count]; i++) {
            BWIndexPath *indexPath = list[i];
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
    for (BWIndexPath *indexPath in indexPaths) {
        [cells addObject:[self cellAtIndexPath:indexPath]];
    }
    return cells.copy;
}

- (BrickworkViewCell *)cellAtIndexPath:(BWIndexPath *)indexPath
{
    BrickworkViewCell *cell = [self.brickDataSource brickworkView:self cellAtIndex:indexPath.index];
    cell.bwIndex = indexPath.index;

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
    if ([self.brickDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.brickDelegate scrollViewDidScroll:scrollView];
    }

    CGFloat bottomEdge = scrollView.contentOffset.y + CGRectGetHeight(scrollView.frame);
    if (bottomEdge >= floor(scrollView.contentSize.height)) {
        [self scrollBelowBottom];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.brickDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.brickDelegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.brickDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.brickDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if ([self.brickDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [self.brickDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.brickDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.brickDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollBelowBottom
{
    if (self.loading) {
        return;
    }

    self.loading = YES;
    if ([self.brickDelegate respondsToSelector:@selector(brickworkView:didScrollBelowBottomWithOffset:)]) {
        [self.brickDelegate brickworkView:self didScrollBelowBottomWithOffset:self.contentOffset];
    }
}
@end
