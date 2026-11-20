//
//  GameView.m
//  Freecell
//
//  Created by Alisdair McDiarmid on Thu Jul 03 2003.
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

#import "GameView.h"
#import "Card.h"
#import "CardView.h"
#import "Game.h"
#import "Table.h"

@implementation GameView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        // Default colour is a nice shade of green
        NSColor *colour = [NSColor colorWithSRGBRed:0.2 green:0.4 blue:0.1 alpha:1.0];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:colour requiringSecureCoding:YES error:nil];

        // Set the default
        [defaults registerDefaults:@{ @"backgroundColour" : data ?: [NSData data], @"gameCardSize" : @50.0 }];

        // Then try to read the preference
        data = [defaults dataForKey:@"backgroundColour"];
        if (data) {
            NSColor *savedColour = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:data error:nil];
            if (savedColour) colour = savedColour;
        }

        // And set the coloour
        [self setBackgroundColour:colour];
    }

    return self;
}

- (void)drawRect:(NSRect)rect {
    int i;
    NSRect frame = [self frame];

    [self.backgroundColour set];
    [NSBezierPath fillRect:frame];

    if (self.game == nil || self.cardView == nil) return;

    for (i = 0; i < TableNumberOfFreeCells; i++) {
        TableLocation *location = [TableLocation locationWithType:TableLocationTypeFreeCell number:i];
        NSPoint origin = NSMakePoint(self.edgeMargin + (self.cardWidth + self.margin) * i,
                                     frame.size.height - self.edgeMargin - self.cardHeight);
        Card *card = [self.table firstCardAtLocation:location];
        BOOL selected = [self.game isTableLocationSelected:location];
        NSImage *image = [self.cardView imageForCard:card selected:selected];
        NSCompositingOperation operation;

        if (card == nil && !selected)
            operation = NSCompositingOperationPlusLighter;
        else
            operation = NSCompositingOperationSourceOver;

        [image drawAtPoint:origin fromRect:NSZeroRect operation:operation fraction:card == nil ? 0.5 : 1.0];
    }

    for (i = 0; i < TableNumberOfStacks; i++) {
        TableLocation *location = [TableLocation locationWithType:TableLocationTypeStack number:i];
        NSPoint origin = NSMakePoint(self.edgeMargin + (self.cardWidth + self.margin) * (i + 4),
                                     frame.size.height - self.edgeMargin - self.cardHeight);
        Card *card = [self.table firstCardAtLocation:location];
        BOOL selected = [self.game isTableLocationSelected:location];
        NSImage *image = [self.cardView imageForCard:card selected:selected];
        NSCompositingOperation operation;

        if (card == nil && !selected)
            operation = NSCompositingOperationPlusLighter;
        else
            operation = NSCompositingOperationSourceOver;

        [image drawAtPoint:origin fromRect:NSZeroRect operation:operation fraction:card == nil ? 0.25 : 1.0];
    }

    for (i = 0; i < TableNumberOfColumns; i++) {
        TableLocation *location = [TableLocation locationWithType:TableLocationTypeColumn number:i];
        NSArray *column = [self.table arrayForLocation:location];
        int row;
        NSUInteger count = [column count];
        unsigned maxHeight = 19 * self.smallOverlap;
        unsigned short o;

        o = (count * self.overlap > maxHeight) ? maxHeight / count : self.overlap;

        row = 0;
        for (Card *card in column) {
            NSPoint origin =
                NSMakePoint(self.edgeMargin + (self.cardWidth + self.margin) * i,
                            frame.size.height - self.edgeMargin - (self.cardHeight + self.margin) * 2 - o * row);
            NSImage *image = [self.cardView imageForCard:card selected:[self.game isCardSelected:card]];
            [image drawAtPoint:origin
                       fromRect:NSZeroRect
                      operation:NSCompositingOperationSourceOver
                       fraction:1.0];
            row++;
        }

        // If the column is empty and selected, draw the selected image
        if (row == 0 && [self.game isTableLocationSelected:[TableLocation locationWithType:TableLocationTypeColumn
                                                                                    number:i]]) {
            NSPoint origin = NSMakePoint(self.edgeMargin + (self.cardWidth + self.margin) * i,
                                         frame.size.height - self.edgeMargin - (self.cardHeight + self.margin) * 2);
            NSImage *image = [self.cardView imageForCard:nil selected:YES];
            [image drawAtPoint:origin
                       fromRect:NSZeroRect
                      operation:NSCompositingOperationPlusDarker
                       fraction:0.5];
        }
    }
}

- (void)mouseDown:(NSEvent *)event {
    TableLocation *location = nil;
    NSPoint pos = [event locationInWindow];
    NSRect frame = [self frame];

    if (pos.x > self.edgeMargin && pos.x < frame.size.width - self.edgeMargin &&
        pos.y < frame.size.height - self.edgeMargin) {
        if (pos.y >= frame.size.height - self.cardHeight - self.margin) {
            if (pos.x < self.edgeMargin + (self.cardWidth + self.margin) * (CGFloat)TableNumberOfFreeCells)
                location = [TableLocation locationWithType:TableLocationTypeFreeCell
                                                    number:(pos.x - self.edgeMargin) / (self.cardWidth + self.margin)];
            else
                location =
                    [TableLocation locationWithType:TableLocationTypeStack
                                             number:(pos.x - self.edgeMargin) / (self.cardWidth + self.margin) - 4];
        } else if (pos.y <= frame.size.height - self.cardHeight - self.margin * 2)
            location = [TableLocation locationWithType:TableLocationTypeColumn
                                                number:(pos.x - self.edgeMargin) / (self.cardWidth + self.margin)];
    }

    if (location) {
        // Take any even number of clicks as a double-click. This allows a
        // quad-click to be understood as two double-clicks in quick succession,
        // which makes perfect UI sense in this case.
        if (([event clickCount] % 2) == 0)
            [self.game doubleClickedTableLocation:location];
        else
            [self.game clickedTableLocation:location];
    }
}

// Mutators
//

- (void)setGame:(Game *)newGame {
    _game = newGame;
    _table = [_game table];
    [self setNeedsDisplay:YES];
}

- (void)setController:(GameController *)newController;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double sliderValue = [defaults doubleForKey:@"gameCardSize"];
    double scale = 0.5 + sliderValue / 100.0;
    CardView *view = [CardView cardView];

    [view setCardSize:NSMakeSize(95 * scale, 140 * scale)];
    _controller = newController;
    [self setCardView:view];
}

+ (NSSize)windowSizeForCardView:(CardView *)cardView {
    unsigned short cardWidth = cardView.cardSize.width;
    unsigned short cardHeight = cardView.cardSize.height;
    unsigned short smallOverlap = cardView.smallOverlap;
    return NSMakeSize(16 + (cardWidth + 8) * 8 - 8 + 16,
                      16 + (cardHeight + 8) * 2 + smallOverlap * 18 + 16 + 22);
}

- (void)setCardView:(CardView *)newCardView {
    _cardView = newCardView;

    // Calculate frame size

    self.margin = 8;
    self.edgeMargin = 2 * self.margin;
    self.overlap = [_cardView overlap];
    self.smallOverlap = [_cardView smallOverlap];
    self.cardWidth = [_cardView cardSize].width;
    self.cardHeight = [_cardView cardSize].height;

    [self.controller setWindowSize:[GameView windowSizeForCardView:newCardView]];
    [self setNeedsDisplay:YES];
}

- (void)setBackgroundColour:(NSColor *)colour {
    _backgroundColour = colour;
    [self setNeedsDisplay:YES];
}

@end
