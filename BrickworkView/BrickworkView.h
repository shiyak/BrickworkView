//
//  BrickworkView.h
//  BrickworkView
//
//  Created by Hirohisa Kawasaki on 13/04/17.
//  Copyright (c) 2013年 Hirohisa Kawasaki. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BrickworkView;

@interface BrickworkViewCell : UIView
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
@end

@protocol BrickworkViewDelegate <NSObject>
@required
- (CGFloat)brickworkView:(BrickworkView *)brickworkView heightForCellAtIndex:(NSInteger)index;
@optional
- (void)brickworkView:(BrickworkView *)brickworkView didSelect:(BrickworkViewCell *)cell AtIndex:(NSInteger)index;
- (void)brickworkView:(BrickworkView *)brickworkView didLongPress:(BrickworkViewCell *)cell AtIndex:(NSInteger)index;
- (void)brickworkView:(BrickworkView *)brickworkView didScrollBelowBottomWithOffset:(CGPoint)offset;
@end

@protocol BrickworkViewDataSource <NSObject>
@required
- (NSInteger)numberOfCellsInBrickworkView:(BrickworkView *)brickworkView;
- (NSInteger)numberOfColumnsInBrickworkView:(BrickworkView *)brickworkView;
- (BrickworkViewCell *)brickworkView:(BrickworkView *)brickworkView cellAtIndex:(NSInteger)index;
@end

@interface BrickworkView : UIScrollView
@property (nonatomic, assign) id<BrickworkViewDataSource> brickDataSource;
@property (nonatomic, assign) id<BrickworkViewDelegate> brickDelegate;
@property (nonatomic) CGFloat padding; // default 0.
@property (nonatomic, readonly) CGFloat widthOfCell;

@property(nonatomic, strong) UIView *headerView;
@property(nonatomic, strong) UIView *footerView;

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (void)refreshData; // clear visibleCells to reloadData
- (void)reloadData;
@end
