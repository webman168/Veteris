//
//  HomeTableViewCell.m
//  Veteris
//
//  Created by electimon on 1/5/24.
//  Copyright (c) 2024 1pwn. All rights reserved.
//

#import "HomeTableViewCell.h"

static const CGFloat HomeCellHorizontalPadding = 20.0f;
static const CGFloat HomeCellContentTop = 48.0f;
static const CGFloat HomeCellBottomPadding = 10.0f;
static const CGFloat HomeCellMinimumHeight = 90.0f;
static const CGFloat HomeCellContentFontSize = 17.0f;

@interface TopAlignedLabel : UILabel
@end

@implementation TopAlignedLabel

- (UIFont *)fontThatFitsBounds:(CGRect)bounds
{
    if (!self.adjustsFontSizeToFitWidth || self.text.length == 0) {
        return self.font;
    }

    CGFloat minimumSize = self.minimumFontSize > 0 ? self.minimumFontSize : 9.0f;
    for (CGFloat size = self.font.pointSize; size >= minimumSize; size -= 1.0f) {
        UIFont *candidateFont = [self.font fontWithSize:size];
        CGSize constrainedSize = CGSizeMake(bounds.size.width, CGFLOAT_MAX);
        CGSize textSize = [self.text sizeWithFont:candidateFont constrainedToSize:constrainedSize lineBreakMode:self.lineBreakMode];
        if (textSize.width <= bounds.size.width && textSize.height <= bounds.size.height) {
            return candidateFont;
        }
    }
    return [self.font fontWithSize:minimumSize];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    CGRect textRect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    textRect.origin.x = bounds.origin.x;
    textRect.origin.y = bounds.origin.y;
    textRect.size.width = bounds.size.width;
    return textRect;
}

- (void)drawTextInRect:(CGRect)rect
{
    UIFont *originalFont = self.font;
    self.font = [self fontThatFitsBounds:rect];
    [super drawTextInRect:[self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines]];
    self.font = originalFont;
}

@end

@implementation HomeTableViewCell
@synthesize headlineLabel;
@synthesize dateLabel;
@synthesize contentLabel;

+ (CGFloat)heightForContentText:(NSString *)text tableWidth:(CGFloat)tableWidth
{
    CGFloat contentWidth = tableWidth - (HomeCellHorizontalPadding * 2.0f);
    if (contentWidth < 1.0f) {
        contentWidth = 1.0f;
    }

    CGSize contentSize = CGSizeZero;
    if ([text length] > 0) {
        CGSize constrainedSize = CGSizeMake(contentWidth, CGFLOAT_MAX);
        contentSize = [text sizeWithFont:[UIFont systemFontOfSize:HomeCellContentFontSize]
                       constrainedToSize:constrainedSize
                           lineBreakMode:NSLineBreakByWordWrapping];
    }

    CGFloat calculatedHeight = HomeCellContentTop + contentSize.height + HomeCellBottomPadding;
    return MAX(HomeCellMinimumHeight, ceilf(calculatedHeight));
}

- (void)replaceContentLabelWithTopAlignedLabel
{
    if (contentLabel == nil || [contentLabel isKindOfClass:[TopAlignedLabel class]]) {
        return;
    }

    UILabel *oldLabel = contentLabel;
    TopAlignedLabel *topLabel = [[TopAlignedLabel alloc] initWithFrame:oldLabel.frame];
    topLabel.autoresizingMask = oldLabel.autoresizingMask;
    topLabel.opaque = oldLabel.opaque;
    topLabel.clipsToBounds = oldLabel.clipsToBounds;
    topLabel.userInteractionEnabled = oldLabel.userInteractionEnabled;
    topLabel.contentMode = oldLabel.contentMode;
    topLabel.backgroundColor = oldLabel.backgroundColor;
    topLabel.textColor = oldLabel.textColor;
    topLabel.highlightedTextColor = oldLabel.highlightedTextColor;
    topLabel.font = oldLabel.font;
    topLabel.textAlignment = oldLabel.textAlignment;
    topLabel.lineBreakMode = oldLabel.lineBreakMode;
    topLabel.numberOfLines = oldLabel.numberOfLines;
    topLabel.baselineAdjustment = oldLabel.baselineAdjustment;
    topLabel.adjustsFontSizeToFitWidth = oldLabel.adjustsFontSizeToFitWidth;
    topLabel.minimumFontSize = oldLabel.minimumFontSize;
    topLabel.text = oldLabel.text;
    topLabel.tag = oldLabel.tag;

    UIView *superview = oldLabel.superview;
    NSUInteger labelIndex = [superview.subviews indexOfObject:oldLabel];
    [oldLabel removeFromSuperview];
    if (labelIndex == NSNotFound) {
        [superview addSubview:topLabel];
    } else {
        [superview insertSubview:topLabel atIndex:labelIndex];
    }
    self.contentLabel = topLabel;
}

- (void)configureContentLabelForDynamicHeight
{
    contentLabel.numberOfLines = 0;
    contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    contentLabel.adjustsFontSizeToFitWidth = NO;
    contentLabel.minimumFontSize = 9.0f;
    if ([contentLabel respondsToSelector:@selector(setMinimumScaleFactor:)]) {
        [contentLabel setMinimumScaleFactor:0.65f];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [self replaceContentLabelWithTopAlignedLabel];
    [self configureContentLabelForDynamicHeight];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat labelWidth = self.contentView.bounds.size.width - (HomeCellHorizontalPadding * 2.0f);
    if (labelWidth < 1.0f) {
        labelWidth = 1.0f;
    }

    headlineLabel.frame = CGRectMake(HomeCellHorizontalPadding, 2.0f, labelWidth, 21.0f);
    dateLabel.frame = CGRectMake(HomeCellHorizontalPadding, 25.0f, labelWidth, 21.0f);

    CGFloat contentHeight = self.contentView.bounds.size.height - HomeCellContentTop - HomeCellBottomPadding;
    if (contentHeight < 0.0f) {
        contentHeight = 0.0f;
    }
    contentLabel.frame = CGRectMake(HomeCellHorizontalPadding, HomeCellContentTop, labelWidth, contentHeight);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
