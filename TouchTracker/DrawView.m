//
//  DrawView.m
//  TouchTracker
//
//  Created by Ernald on 5/20/16.
//  Copyright © 2016 Big Nerd. All rights reserved.
//

#import "DrawView.h"
#import "DrawLine.h"

@interface DrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSValue *, DrawLine *> *currentLinesInProgress;

@property (nonatomic, strong) NSMutableArray<DrawLine *> *finishedLines;

@property (nonatomic, weak) DrawLine *selectedLine;

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;

@end

@implementation DrawView

- (instancetype)initWithFrame: (CGRect) frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        _currentLinesInProgress = [NSMutableDictionary new];
        _finishedLines = [NSMutableArray new];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = TRUE;
        
        UITapGestureRecognizer *doubleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapGR.numberOfTapsRequired = 2;
        doubleTapGR.delaysTouchesBegan = YES;
        
        [self addGestureRecognizer:doubleTapGR];
        
        UITapGestureRecognizer *singleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        
        [singleTapGR requireGestureRecognizerToFail:doubleTapGR];
        
        [self addGestureRecognizer:singleTapGR];
        
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        
        [self addGestureRecognizer:longPressGR];
        
        [singleTapGR requireGestureRecognizerToFail:longPressGR];
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        self.moveRecognizer.delaysTouchesBegan = YES;
        
        [self addGestureRecognizer:self.moveRecognizer];
    }
    
    return self;
}

- (void) moveLine: (UIPanGestureRecognizer*) panGestureRecognizer
{
    if(!self.selectedLine)
    {
        return;
    }
    
    if(panGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        NSLog(@"%@", NSStringFromSelector(_cmd));
        CGPoint translation = [panGestureRecognizer translationInView:self];
        
        self.selectedLine.begin = CGPointMake(self.selectedLine.begin.x + translation.x, self.selectedLine.begin.y + translation.y);
        
        self.selectedLine.end = CGPointMake(self.selectedLine.end.x + translation.x, self.selectedLine.end.y + translation.y);
        
        [self setNeedsDisplay];
        
        [panGestureRecognizer setTranslation:CGPointZero inView:self];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if(gestureRecognizer == self.moveRecognizer)
    {
        return YES;
    }
    
    return NO;
}

- (void) doubleTap: (UIGestureRecognizer *) gestureRecognizer
{
    NSLog(@"Recognized double tap");
    
    [self.currentLinesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

- (void) singleTap: (UIGestureRecognizer *) gestureRecognizer
{
    NSLog(@"Recognized single tap");
    
    CGPoint point = [gestureRecognizer locationInView:self];
    
    self.selectedLine = [self lineAtPoint:point];
    
    if(self.selectedLine)
    {
        [self becomeFirstResponder];
        
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        UIMenuItem *deleteMenuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine)];
        
        menu.menuItems = @[deleteMenuItem];
        
        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
    else
    {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
}

- (void) longPress: (UIGestureRecognizer *) gestureRecognizer
{
    NSLog(@"Recognized long press");
    
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point = [gestureRecognizer locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if(self.selectedLine)
        {
            [self.currentLinesInProgress removeAllObjects];
        }
    }
    else if(gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        self.selectedLine = nil;
    }
    
    [self setNeedsDisplay];
}

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void) deleteLine
{
    [self.finishedLines removeObject:self.selectedLine];
    
    [self setNeedsDisplay];
}

- (DrawLine *) lineAtPoint: (CGPoint) p
{
    for(DrawLine *line in self.finishedLines)
    {
        CGPoint start = line.begin;
        CGPoint end = line.end;
        
        for(float t = 0.0; t < 1.0; t += 0.05)
        {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            if(hypot(x - p.x, y - p.y) < 20.0)
            {
                return line;
            }
        }
    }
    
    return nil;
}

- (void) strokeLine: (DrawLine *) line
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 10;
    path.lineCapStyle = kCGLineCapRound;
    
    [path moveToPoint: line.begin];
    [path addLineToPoint: line.end];
    [path stroke];
}

- (void)drawRect:(CGRect)rect
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    [[UIColor blackColor] set];
    
    for(DrawLine *line in self.finishedLines)
    {
        [self strokeLine: line];
    }
    
    if(self.selectedLine)
    {
        [[UIColor greenColor] set];
        [self strokeLine: self.selectedLine];
    }
    
    for(DrawLine *line in [self.currentLinesInProgress allValues])
    {
        [[UIColor redColor] set];
        [self strokeLine: line];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for(UITouch *touch in touches)
    {
        CGPoint touchSpot = [touch locationInView:self];
        
        DrawLine *newLine = [DrawLine new];
        newLine.begin = touchSpot;
        newLine.end = touchSpot;
        
        [self.currentLinesInProgress setObject:newLine
                                        forKey:[NSValue valueWithNonretainedObject:touch]];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    for(UITouch *touch in touches)
    {
        CGPoint touchSpot = [touch locationInView:self];
        DrawLine* currentLine = self.currentLinesInProgress[[NSValue valueWithNonretainedObject:touch]];
        currentLine.end = touchSpot;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for(UITouch *touch in touches)
    {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        
        DrawLine *newLine = self.currentLinesInProgress[key];
        [self.finishedLines addObject:newLine];
        [self.currentLinesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for(UITouch *touch in touches)
    {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        [self.currentLinesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

@end
