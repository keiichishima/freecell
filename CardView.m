//
//  CardView.m
//  Freecell
//
//  Created by Alisdair McDiarmid on Sun Jul 06 2003.
//  Copyright (c) 2003 Alisdair McDiarmid. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//   
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//  
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//   
//  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
//  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
//  ALISDAIR MCDIARMID BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//
//  CardView.m
//  Freecell
//

#import <AppKit/AppKit.h>
#import "CardView.h"

static const CGFloat kImageEdgeMarginRatio = 0.02;
static const CGFloat kCornerRoundRatio = 0.1;

@implementation CardView

+ cardView
{
    return [[CardView alloc] init];
}

- init
{
    self = [super init];
    if (self) {
        svgCache = [[NSMutableDictionary alloc] init];
        cardSize = NSMakeSize(95, 140);
    }
    return self;
}

- (NSString *) svgFilenameForCard: (Card *) card
{
    NSString *rankStr;
    switch ([card rank]) {
        case RankAce:   rankStr = @"ace"; break;
        case RankJack:  rankStr = @"jack"; break;
        case RankQueen: rankStr = @"queen"; break;
        case RankKing:  rankStr = @"king"; break;
        default:    rankStr = [NSString stringWithFormat:@"%ld", [card rank]]; break;
    }
    return [NSString stringWithFormat: @"%@_of_%@", rankStr, [[card suitString] lowercaseString]];
}

- (NSImage *) svgImageForCard: (Card *) card
{
    if (card == nil) return nil;
    
    NSString *filename = [self svgFilenameForCard: card];
    NSImage *cachedImage = [svgCache objectForKey: filename];
    if (cachedImage != nil) return cachedImage;
    
    NSString *svgPath = [[NSBundle mainBundle] pathForResource: filename ofType: @"svg"];
    if (svgPath == nil) return nil;
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile: svgPath];
    if (image) {
        [svgCache setObject: image forKey: filename];
    }
    return [svgCache objectForKey: filename];
}

- (NSImage *) imageForCard: (Card *) card selected: (BOOL) isSelected
{
    return [NSImage imageWithSize:cardSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        CGFloat cornerRadius = dstRect.size.width * kCornerRoundRatio;

        // 1. draw background with rounded corners
        [[NSColor whiteColor] set];
        NSBezierPath *cardPath = [NSBezierPath bezierPathWithRoundedRect:dstRect
                                                                 xRadius:cornerRadius
                                                                 yRadius:cornerRadius];
        [cardPath fill];
        
        // 2. draw card image
        if (card != nil) {
            NSImage *svgImage = [self svgImageForCard:card];
            CGFloat xmargin = dstRect.size.width * kImageEdgeMarginRatio;
            CGFloat ymargin = dstRect.size.height * kImageEdgeMarginRatio;
            NSRect innerRect = NSMakeRect(xmargin, ymargin, dstRect.size.width - xmargin * 2, dstRect.size.height - ymargin * 2);
            [svgImage drawInRect:innerRect
                        fromRect:NSZeroRect
                       operation:NSCompositingOperationSourceOver
                        fraction:1.0];
        }
        
        // 3. draw overlay image when selected
        if (isSelected) {
            [[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:0.3] set];
            NSBezierPath *overlayPath = [NSBezierPath bezierPathWithRoundedRect:dstRect xRadius:8 yRadius:8];
            [overlayPath fill];
        }
        
        // 4. draw surrounding lines with rounded corners
        [[NSColor blackColor] set];
        NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0.5, 0.5, dstRect.size.width - 1, dstRect.size.height - 1) xRadius:cornerRadius yRadius:cornerRadius];
        [borderPath stroke];
        
        return YES;
    }];
}

- (NSSize) size
{
    return cardSize;
}

- (void) setCardSize: (NSSize) newSize
{
    cardSize = newSize;
}

- (unsigned) overlap
{
    return cardSize.height / 3;
}

- (unsigned) smallOverlap
{
    return cardSize.height / 4.75;
}

@end
