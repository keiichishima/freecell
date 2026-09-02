//
//  Game.m
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

#import "Game.h"
#include <stdlib.h>
#import "Card.h"
#import "GameController.h"
#import "GameView.h"
#import "Table.h"
#include "vccRand.h"

@interface Game ()

@property(nonatomic, strong) NSUserDefaults *defaults;
@property(nonatomic, copy) TableMove *move;
@property(nonatomic, strong) NSMutableArray *played;
@property(nonatomic, strong) NSMutableArray *undone;

@property(nonatomic, strong, readwrite) Table *table;
@property(nonatomic, copy, readwrite) NSNumber *gameNumber;
@property(nonatomic, strong, readwrite) Result *result;
@property(nonatomic, assign, getter=isInProgress, readwrite) BOOL inProgress;

- (void)G_deal;
- (void)G_attemptMove;
- (void)G_moreMoves;
- (void)G_autoStack;

@end

@implementation Game

+ (instancetype)gameWithView:(GameView *)newView
                  controller:(GameController *)newController
                  gameNumber:(NSNumber *)newGameNumber {
    return [[self alloc] initWithView:newView controller:newController gameNumber:newGameNumber];
}

- (instancetype)initWithView:(GameView *)newView
                  controller:(GameController *)newController
                  gameNumber:(NSNumber *)newGameNumber {
    self = [super init];

    if (self) {
        _view = newView;
        _controller = newController;
        _defaults = [NSUserDefaults standardUserDefaults];
        _gameNumber = [newGameNumber copy];
        _table = [[Table alloc] init];

        [self G_deal];

        _result = [Result resultWithUnplayed];
        _played = [[NSMutableArray alloc] init];
        _undone = [[NSMutableArray alloc] init];

        _startDate = [NSDate date];
        _inProgress = NO;

        [_view setNeedsDisplay:YES];
    }
    return self;
}

// Private methods
//

- (void)G_deal {
    TableLocation *deckTableLocation = [TableLocation locationWithType:TableLocationTypeDeck number:0];
    NSMutableArray *deck = (NSMutableArray *)[self.table arrayForLocation:deckTableLocation];
    NSUInteger i, n;

    // Shuffle the deck
    vcpp_srand((unsigned int)[self.gameNumber doubleValue]);
    for (i = [deck count]; i > 0; i--) {
        unsigned j = vcpp_rand() % i;
        [deck exchangeObjectAtIndex:(i - 1) withObjectAtIndex:j];
    }

    // Lay out table
    n = [deck count];
    for (i = 0; i < n; i++) {
        TableLocation *column = [TableLocation locationWithType:TableLocationTypeColumn
                                                         number:i % TableNumberOfColumns];
        [self.table move:[TableMove moveFromSource:deckTableLocation toDestination:column]];
    }
}

- (void)G_attemptMove {
    [self.move setCount:0];

    if ([[self.move source] type] == TableLocationTypeColumn &&
        [[self.move destination] type] == TableLocationTypeColumn) {
        NSUInteger emptyFreeCells = [self.table numberOfEmptyTableLocationType:TableLocationTypeFreeCell];
        NSUInteger emptyColumns = [self.table numberOfEmptyTableLocationType:TableLocationTypeColumn];
        NSUInteger count;

        // The maximum number of cards which may be played with F empty free
        // cells is F + 1. However, this is doubled for every empty column,
        // except for the destination column.
        if (emptyColumns > 0 && [self.table cardNumber:1 atTableLocation:[self.move destination]] == nil)
            emptyColumns--;

        // If super-move is disabled, just pretend there are no empty free cells or columns.
        if ([self.defaults boolForKey:@"gameSuperMove"] == NO) emptyFreeCells = emptyColumns = 0;

        // So, the maximum number of cards is (F + 1) * 2^C, and
        // 2^C == 1 << C.
        for (count = (emptyFreeCells + 1) * (1 << emptyColumns); count > 0; count--) {
            NSUInteger try
                ;

            // Check that the `count' cards are in valid sequence; break from the
            // loop if they are not.
            for (try = count; try > 1; try --)
                if (![[self.table cardNumber:try - 1 atTableLocation:[self.move source]]
                        isPlayableOn:[self.table cardNumber:try atTableLocation:[self.move source]]])
                    break;

            // The condition `try == 1' is YES iff the card sequence is valid.
            if (try == 1 && [[self.table cardNumber:count atTableLocation:[self.move source]]
                                isPlayableOn:[self.table firstCardAtLocation:[self.move destination]]]) {
                [self.move setCount:count];
                break;
            }
        }
    } else if ([[self.move destination] type] == TableLocationTypeStack) {
        if ([[self.table firstCardAtLocation:[self.move source]]
                isSuccessorTo:[self.table firstCardAtLocation:[self.move destination]]])
            [self.move setCount:1];
    } else if ([[self.move destination] type] == TableLocationTypeColumn) {
        if ([[self.table firstCardAtLocation:[self.move source]]
                isPlayableOn:[self.table firstCardAtLocation:[self.move destination]]])
            [self.move setCount:1];
    } else if ([[self.move destination] type] == TableLocationTypeFreeCell) {
        if ([[self.table arrayForLocation:[self.move destination]] count] == 0) [self.move setCount:1];
    }

    if ([self.move count] > 0) {
        if (self.inProgress == NO) {
            self.inProgress = YES;
            self.startDate = [NSDate date];
        }
        [self.table move:self.move];
        [self.undone removeAllObjects];
        [self.played addObject:self.move];
        [self.controller moveMade];
    }

    self.move = nil;
    [self.view display];
    [self G_moreMoves];
    if ([self.defaults boolForKey:@"gameAutoStack"] == YES) [self G_autoStack];
}

- (void)G_moreMoves {
    unsigned i;
    Card *card;

    for (i = 0; i < TableNumberOfStacks; i++)
        if ([[self.table cardNumber:1
                    atTableLocation:[TableLocation locationWithType:TableLocationTypeStack number:i]] rank] != RankKing)
            break;

    if (i == TableNumberOfStacks) {
        [self gameOverWithResult:[Result resultWithWin]];
        [self.controller gameOver];
        return;
    }

    if ([self.table numberOfEmptyTableLocationType:TableLocationTypeFreeCell] != 0) return;

    for (i = 0; i < TableNumberOfFreeCells; i++) {
        unsigned j;

        card = [self.table firstCardAtLocation:[TableLocation locationWithType:TableLocationTypeFreeCell number:i]];
        for (j = 0; j < TableNumberOfStacks; j++) {
            Card *other = [self.table firstCardAtLocation:[TableLocation locationWithType:TableLocationTypeStack
                                                                                   number:j]];
            if ([card isSuccessorTo:other]) return;
        }

        for (j = 0; j < TableNumberOfColumns; j++) {
            Card *other = [self.table firstCardAtLocation:[TableLocation locationWithType:TableLocationTypeColumn
                                                                                   number:j]];
            if ([card isPlayableOn:other]) return;
        }
    }

    for (i = 0; i < TableNumberOfColumns; i++) {
        unsigned j;

        card = [self.table firstCardAtLocation:[TableLocation locationWithType:TableLocationTypeColumn number:i]];
        for (j = 0; j < TableNumberOfStacks; j++) {
            Card *other = [self.table firstCardAtLocation:[TableLocation locationWithType:TableLocationTypeStack
                                                                                   number:j]];
            if ([card isSuccessorTo:other]) return;
        }

        for (j = 0; j < TableNumberOfColumns; j++) {
            Card *other = [self.table firstCardAtLocation:[TableLocation locationWithType:TableLocationTypeColumn
                                                                                   number:j]];
            if ([card isPlayableOn:other]) return;
        }
    }

    [self gameOverWithResult:[Result resultWithLoss]];
    [self.controller gameOver];
}

- (void)G_autoStack {
    NSInteger minimumStackedRank;
    TableLocation *source, *destination;
    Card *card, *other;

    minimumStackedRank = RankKing;
    for (NSInteger i = 0; i < TableNumberOfStacks; i++) {
        TableLocation *stack = [TableLocation locationWithType:TableLocationTypeStack number:i];
        NSInteger rank = [[self.table firstCardAtLocation:stack] rank];
        if (rank < minimumStackedRank) minimumStackedRank = rank;
    }

    for (NSInteger i = 0; i < TableNumberOfFreeCells; i++) {
        unsigned j;

        source = [TableLocation locationWithType:TableLocationTypeFreeCell number:i];
        card = [self.table firstCardAtLocation:source];

        for (j = 0; j < TableNumberOfStacks; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeStack number:j];
            other = [self.table firstCardAtLocation:destination];
            if ([card isSuccessorTo:other] && [card rank] < minimumStackedRank + 3) goto makeMove;
        }
    }

    for (NSInteger i = 0; i < TableNumberOfColumns; i++) {
        unsigned j;

        source = [TableLocation locationWithType:TableLocationTypeColumn number:i];
        card = [self.table firstCardAtLocation:source];

        for (j = 0; j < TableNumberOfStacks; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeStack number:j];
            other = [self.table firstCardAtLocation:destination];
            if ([card isSuccessorTo:other] && [card rank] < minimumStackedRank + 3) goto makeMove;
        }
    }

    // No safe auto-stack possible
    return;

makeMove:
    self.move = [TableMove moveFromSource:source toDestination:destination];
    [self G_attemptMove];
}

// Mutators
//
- (void)undo {
    if ([self.played count] > 0) {
        TableMove *undoMove = [TableMove reverseMove:[self.played lastObject]];

        [self.undone addObject:undoMove];
        [self.played removeLastObject];
        [self.table move:undoMove];

        [self.controller moveMade];
        [self.view setNeedsDisplay:YES];
    }
}

- (void)redo {
    if ([self.undone count] > 0) {
        TableMove *redoMove = [TableMove reverseMove:[self.undone lastObject]];

        [self.played addObject:redoMove];
        [self.undone removeLastObject];
        [self.table move:redoMove];

        [self.controller moveMade];
        [self.view setNeedsDisplay:YES];
    }
}

- (void)clickedTableLocation:(TableLocation *)location {
    // If a move hasn't been started yet, and the location clicked can be
    // moved from (it's a free cell or a column), start the move.
    if (self.move == nil) {
        if (([location type] == TableLocationTypeFreeCell || [location type] == TableLocationTypeColumn) &&
            [self.table firstCardAtLocation:location] != nil) {
            self.move = [TableMove moveFromSource:location];
            [self.view setNeedsDisplay:YES];
        }
        return;
    }

    // Otherwise, a move has been started, and this is the desired destination.
    [self.move setDestination:location];

    [self G_attemptMove];
}

- (void)doubleClickedTableLocation:(TableLocation *)source {
    unsigned i;

    self.move = [TableMove moveFromSource:source];

    for (i = 0; i < TableNumberOfFreeCells; i++) {
        TableLocation *freeCell = [TableLocation locationWithType:TableLocationTypeFreeCell number:i];

        if ([self.table firstCardAtLocation:freeCell] == nil) {
            [self.move setDestination:freeCell];
            break;
        }
    }

    [self G_attemptMove];
}

- (void)setHint {
    Card *card, *other;
    TableLocation *source, *destination;

    for (NSInteger i = 0; i < TableNumberOfColumns; i++) {
        source = [TableLocation locationWithType:TableLocationTypeColumn number:i];
        card = [self.table firstCardAtLocation:source];
        for (NSInteger j = 0; j < TableNumberOfStacks; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeStack number:j];
            other = [self.table firstCardAtLocation:destination];
            if ([card isSuccessorTo:other]) goto foundHint;
        }
        for (NSInteger j = 0; j < TableNumberOfColumns; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeColumn number:j];
            other = [self.table firstCardAtLocation:destination];
            if ([card isPlayableOn:other]) goto foundHint;
        }
    }

    for (NSInteger i = 0; i < TableNumberOfFreeCells; i++) {
        source = [TableLocation locationWithType:TableLocationTypeFreeCell number:i];
        card = [self.table firstCardAtLocation:source];
        for (NSInteger j = 0; j < TableNumberOfStacks; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeStack number:j];
            other = [self.table firstCardAtLocation:destination];
            if ([card isSuccessorTo:other]) goto foundHint;
        }
        for (NSInteger j = 0; j < TableNumberOfColumns; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeColumn number:j];
            other = [self.table firstCardAtLocation:destination];
            if ([card isPlayableOn:other]) goto foundHint;
        }
    }

    for (NSInteger i = 0; i < TableNumberOfColumns; i++) {
        source = [TableLocation locationWithType:TableLocationTypeColumn number:i];
        if ([self.table firstCardAtLocation:source] == nil) continue;

        for (NSInteger j = 0; j < TableNumberOfFreeCells; j++) {
            destination = [TableLocation locationWithType:TableLocationTypeFreeCell number:j];
            if ([self.table firstCardAtLocation:destination] == nil) goto foundHint;
        }
    }

    // No hint found.
    self.hint = nil;
    return;

foundHint:
    [self setHint:[TableMove moveFromSource:source toDestination:destination]];
}

- (void)gameOverWithResult:(Result *)newResult {
    self.endDate = [NSDate date];
    self.result = [newResult copy];
    self.inProgress = NO;
}

// Accessors
//
- (NSUInteger)moves {
    return [self.played count];
}

- (NSTimeInterval)duration {
    return [self.endDate timeIntervalSinceDate:self.startDate];
}

- (BOOL)canUndo {
    return (self.inProgress && [self.played count] > 0);
}

- (BOOL)canRedo {
    return (self.inProgress && [self.undone count] > 0);
}

- (BOOL)isCardSelected:(Card *)card {
    return ([card isEqual:[self.table firstCardAtLocation:[self.move source]]] ||
            [card isEqual:[self.table firstCardAtLocation:[self.hint source]]] ||
            [card isEqual:[self.table firstCardAtLocation:[self.hint destination]]]);
}

- (BOOL)isTableLocationSelected:(TableLocation *)location {
    return ([location isEqual:[self.move source]] || [location isEqual:[self.hint source]] ||
            [location isEqual:[self.hint destination]]);
}

- (NSArray *)movesList {
    NSMutableArray *moves = [NSMutableArray arrayWithCapacity:[self moves]];
    for (TableMove *tableMove in self.played) {
        [moves addObject:[tableMove description]];
    }
    return [NSArray arrayWithArray:moves];
}

@end
