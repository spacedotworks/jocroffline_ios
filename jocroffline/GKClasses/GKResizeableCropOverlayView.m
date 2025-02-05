//
//  GKResizeableView.m
//  GKImagePicker
//
//  Created by Patrick Thonhauser on 9/21/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKResizeableCropOverlayView.h"
#import "GKCropBorderView.h"

#define kBorderCorrectionValue 12


@interface GKResizeableCropOverlayView(){
    CGSize _initialContentSize;
    BOOL _resizingEnabled;
    CGPoint _theAnchor;
    CGPoint _startPoint;
    GKResizeableViewBorderMultiplyer _resizeMultiplyer;
}

-(void)_addContentViews;
-(CGPoint)_calcuateWhichBorderHandleIsTheAnchorPointFromHere:(CGPoint)anchorPoint;
-(NSMutableArray*)_getAllCurrentHandlePositions;
-(void)_resizeWithTouchPoint:(CGPoint)point;
-(void)_fillMultiplyer;
-(CGRect)_preventBorderFrameFromGettingTooSmallOrTooBig:(CGRect)newFrame;

@end

@implementation GKResizeableCropOverlayView



@synthesize contentView = _contentView;
@synthesize cropBorderView = _cropBorderView;

#pragma mark -
#pragma Overriden

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    CGFloat toolbarSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;
    _contentView.frame = CGRectMake(self.bounds.size.width / 2 - _initialContentSize.width  / 2  , (self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2 , _initialContentSize.width, _initialContentSize.height);
    _cropBorderView.frame = CGRectMake(self.bounds.size.width / 2 - _initialContentSize.width  / 2 - kBorderCorrectionValue, (self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2 - kBorderCorrectionValue, _initialContentSize.width + kBorderCorrectionValue*2, _initialContentSize.height + kBorderCorrectionValue*2);
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame andInitialContentSize:(CGSize)contentSize{
    
    self = [super initWithFrame:frame];
    if (self) {
        _initialContentSize = contentSize;
        [self _addContentViews];
    }
    return self;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:_cropBorderView];
    
    
    _theAnchor = [self _calcuateWhichBorderHandleIsTheAnchorPointFromHere:touchPoint];
    [self _fillMultiplyer];
    /*if (CGPointEqualToPoint(_theAnchor, CGPointMake(_cropBorderView.bounds.size.width / 2, _cropBorderView.bounds.size.height / 2))){
     _resizingEnabled = NO;
     return;
     }*/
    _resizingEnabled = YES;
    _startPoint = [touch locationInView:self.superview];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!_resizingEnabled)
        return;
    [self _resizeWithTouchPoint:[[touches anyObject] locationInView:self.superview]];
}

#pragma mark -
#pragma private


//This chunk covers the overlay frames
-(void)_addContentViews{
    CGFloat toolbarSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;

    _contentView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - _initialContentSize.width  / 2  , (self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2 , _initialContentSize.width, _initialContentSize.height)];
    _contentView.backgroundColor = [UIColor clearColor];
    self.cropSize = _contentView.frame.size;
    [self addSubview:_contentView];
   // NSLog(@"x: %f y: %f %f", CGRectGetMinX(_contentView.frame), CGRectGetMinY(_contentView.frame), self.bounds.size.width);
    
//      _cropBorderView = [[GKCropBorderView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - _initialContentSize.width  / 2 - kBorderCorrectionValue, (self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2 - kBorderCorrectionValue, _initialContentSize.width + kBorderCorrectionValue*2, _initialContentSize.height + kBorderCorrectionValue*2)];
    
    _cropBorderView = [[GKCropBorderView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - _initialContentSize.width  / 2 - kBorderCorrectionValue, (self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2 - kBorderCorrectionValue, _initialContentSize.width + kBorderCorrectionValue*2, _initialContentSize.height + kBorderCorrectionValue*2)];
    [self addSubview:_cropBorderView];
}

-(CGPoint)_calcuateWhichBorderHandleIsTheAnchorPointFromHere:(CGPoint)anchorPoint{
    NSMutableArray* allHandles = [self _getAllCurrentHandlePositions];
    
    CGFloat closest = 3000;
    NSValue* theRealAnchor = nil;
    for (NSValue* value in allHandles){
        //Pythagoras is watching you :-)
        CGPoint currentPoint = [value CGPointValue];
        CGFloat xDist = (currentPoint.x - anchorPoint.x);
        CGFloat yDist = (currentPoint.y - anchorPoint.y);
        CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
        
        closest = distance < closest ? distance : closest;
        theRealAnchor = closest == distance ? value : theRealAnchor;
    }
    return [theRealAnchor CGPointValue];
}

-(NSMutableArray*)_getAllCurrentHandlePositions{
    
    NSMutableArray* a = [NSMutableArray new];
    //
    //again starting with the upper left corner and then following the rect clockwise
    CGPoint currentPoint = CGPointMake(0, 0);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
                  
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width / 2, 0);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width, 0);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width, _cropBorderView.bounds.size.height / 2);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width , _cropBorderView.bounds.size.height);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width / 2, _cropBorderView.bounds.size.height);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(0, _cropBorderView.bounds.size.height);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(0, _cropBorderView.bounds.size.height / 2);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    return a;
}

-(void)_resizeWithTouchPoint:(CGPoint)point{
    //This is the place where all the magic happens
    //prevent goint offscreen...
    CGFloat border = kBorderCorrectionValue*2;
    point.x = point.x < border ? border : point.x;
    point.y = point.y < border ? border : point.y;
    point.x = point.x > self.superview.bounds.size.width - border ? point.x = self.superview.bounds.size.width - border : point.x;
    point.y = point.y > self.superview.bounds.size.height - border ? point.y = self.superview.bounds.size.height - border : point.y;
    
    CGFloat heightChange = (point.y - _startPoint.y) * _resizeMultiplyer.heightMultiplyer;
    CGFloat widthChange = (_startPoint.x - point.x) * _resizeMultiplyer.widhtMultiplyer;
    CGFloat xChange = -1 * widthChange * _resizeMultiplyer.xMultiplyer;
    CGFloat yChange = -1 * heightChange * _resizeMultiplyer.yMultiplyer;
    
    CGRect newFrame =  CGRectMake(_cropBorderView.frame.origin.x + xChange, _cropBorderView.frame.origin.y + yChange, _cropBorderView.frame.size.width + widthChange, _cropBorderView.frame.size.height + heightChange);
    
    newFrame = [self _preventBorderFrameFromGettingTooSmallOrTooBig:newFrame];
    
    [self _resetFramesToThisOne:newFrame];
    _startPoint = point;
}

-(CGRect)_preventBorderFrameFromGettingTooSmallOrTooBig:(CGRect)newFrame{
    CGFloat toolbarSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;

    if (newFrame.size.width < 64) {
        newFrame.size.width = _cropBorderView.frame.size.width;
        newFrame.origin.x = _cropBorderView.frame.origin.x;
    }
    if (newFrame.size.height < 64) {
        newFrame.size.height = _cropBorderView.frame.size.height;
        newFrame.origin.y = _cropBorderView.frame.origin.y;
    }
    
    if (newFrame.origin.x < 0){
        newFrame.size.width = _cropBorderView.frame.size.width + (_cropBorderView.frame.origin.x - self.superview.bounds.origin.x);
        newFrame.origin.x = 0;
    }
    
    if (newFrame.origin.y < 0){
        newFrame.size.height = _cropBorderView.frame.size.height + (_cropBorderView.frame.origin.y - self.superview.bounds.origin.y);;
        newFrame.origin. y = 0;
    }
    
    if (newFrame.size.width + newFrame.origin.x > self.frame.size.width)
        newFrame.size.width = self.frame.size.width - _cropBorderView.frame.origin.x;
    
    if (newFrame.size.height + newFrame.origin.y > self.frame.size.height - toolbarSize)
        newFrame.size.height = self.frame.size.height  - _cropBorderView.frame.origin.y - toolbarSize;
    return newFrame;
}

-(void)_resetFramesToThisOne:(CGRect)frame{
    _cropBorderView.frame = frame;
    _contentView.frame = CGRectInset(frame, kBorderCorrectionValue, kBorderCorrectionValue);
    self.cropSize = _contentView.frame.size;
    [self setNeedsDisplay];
    [_cropBorderView setNeedsDisplay];
}

-(void)_fillMultiplyer{    
    //-1 left, 0 middle, 1 right
    _resizeMultiplyer.heightMultiplyer =  (_theAnchor.y == 0 ? -1 : (_theAnchor.y == _cropBorderView.bounds.size.height) ? 1 : 0);
    //-1 up, 0 middle, 1 down
    _resizeMultiplyer.widhtMultiplyer = (_theAnchor.x == 0 ? 1 : (_theAnchor.x == _cropBorderView.bounds.size.width) ? -1 : 0);
    // 1 left, 0 middle, 0 right
    _resizeMultiplyer.xMultiplyer = (_theAnchor.x == 0 ? 1 : 0);
    // 1 up, 0 middle, 0 down
    _resizeMultiplyer.yMultiplyer = (_theAnchor.y == 0 ? 1 : 0);
}

#pragma mark -
#pragma drawing
- (void)drawRect:(CGRect)rect{

    //fill outer rect
    [[UIColor colorWithRed:0. green:0. blue:0. alpha:0.5] set];
    UIRectFill(self.bounds);
    
    //fill inner rect
    [[UIColor clearColor] set];
    UIRectFill(self.contentView.frame);
    
}

@end
