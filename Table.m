//
//  Table.m
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


#import "Table.h"
#import "Card.h"

NSInteger const TableNumberOfColumns = 8;
NSInteger const TableNumberOfStacks = 4;
NSInteger const TableNumberOfFreeCells = 4;
NSInteger const TableNumberOfDecks = 1;

@implementation Table

- init
{

    self = [super init];

    freeCells = [[NSMutableArray alloc] init];
    stacks    = [[NSMutableArray alloc] init];
    columns   = [[NSMutableArray alloc] init];
    decks     = [[NSMutableArray alloc] init];

    for (NSInteger i = 0; i < TableNumberOfFreeCells; i++)
        [freeCells addObject: [NSMutableArray array]];
    for (NSInteger i = 0; i < TableNumberOfStacks; i++)
        [stacks addObject: [NSMutableArray array]];
    for (NSInteger i = 0; i < TableNumberOfColumns; i++)
        [columns addObject: [NSMutableArray array]];
    for (NSInteger i = 0; i < TableNumberOfDecks; i++)
        [decks addObject: [NSMutableArray array]];

    for (NSInteger i = RankAce; i <= RankKing; i++)
    {
        // Use Windows suit ordering
        [[decks lastObject] addObject: [Card cardWithSuit: SuitClubs rank: i]];
        [[decks lastObject] addObject: [Card cardWithSuit: SuitDiamonds rank: i]];
        [[decks lastObject] addObject: [Card cardWithSuit: SuitHearts rank: i]];
        [[decks lastObject] addObject: [Card cardWithSuit: SuitSpades rank: i]];
    }
    return self;
}

// Mutators
//

- (void) move: (TableMove *) move
{
    NSMutableArray *source = (NSMutableArray *) [self arrayForLocation: [move source]];
    NSMutableArray *destination = (NSMutableArray *) [self arrayForLocation: [move destination]];
    unsigned long i, first, last;

    first = [source count] - [move count];
    last  = [source count];
    for (i = first; i < last; i++)
    {
        [destination addObject: [source objectAtIndex: first]];
        [source removeObjectAtIndex: first];
    }
}

// Accessors
//

- (NSArray *) arrayForLocation: (TableLocation *) location
{
    NSArray *locationType = [self arrayForLocationType: [location type]];
    return [locationType objectAtIndex: [location number]];
}

- (NSArray *) arrayForLocationType: (TableLocationType) locationType
{
    switch (locationType)
    {
        case TableLocationTypeNone:	return nil;
        case TableLocationTypeFreeCell:	return freeCells;
        case TableLocationTypeStack:	return stacks;
        case TableLocationTypeColumn:	return columns;
        case TableLocationTypeDeck:	return decks;
    }
    
    return nil;
}

- (unsigned) numberOfEmptyTableLocationType: (TableLocationType) locationType
{
    NSEnumerator *enumerator;
    NSArray *location;
    unsigned n = 0;
    
    enumerator = [[self arrayForLocationType: locationType] objectEnumerator];
    while (location = [enumerator nextObject])
        if ([location count] == 0)
            n++;

    return n;
}

- (Card *) cardNumber: (unsigned) n atTableLocation: (TableLocation *) location
{
    NSArray *array = [self arrayForLocation: location];

    if (n > [array count] || n == 0)
        return nil;
    
    return [array objectAtIndex: [array count] - n];
}

- (Card *) firstCardAtLocation: (TableLocation *) location
{
    return [self cardNumber: 1 atTableLocation: location];
}

@end
