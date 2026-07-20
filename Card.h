//
//  Card.h
//  Freecell
//
//  Created by Alisdair McDiarmid on Sat Jul 05 2003.
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

#import <Foundation/Foundation.h>

// Suit order is important: must match the card graphics file.
typedef NS_ENUM(NSInteger, Suit) {
    SuitClubs,
    SuitDiamonds,
    SuitHearts,
    SuitSpades
};

typedef NS_ENUM(NSInteger, Rank) {
    RankAce = 1,
    RankTwo,
    RankThree,
    RankFour,
    RankFive,
    RankSix,
    RankSeven,
    RankEight,
    RankNine,
    RankTen,
    RankJack,
    RankQueen,
    RankKing
};


@interface Card : NSObject <NSCopying>

@property (nonatomic, assign) Suit suit;
@property (nonatomic, assign) Rank rank;
@property (nonatomic, readonly, copy) NSString *suitString;
@property (nonatomic, readonly, copy) NSString *rankString;
@property (nonatomic, readonly, getter=isRed) BOOL red;
@property (nonatomic, readonly, getter=isBlack) BOOL black;

+ (instancetype)cardWithSuit: (Suit) newSuit rank: (Rank) newRank;
- (instancetype)initWithSuit: (Suit) newSuit rank: (Rank) newRank;

- (BOOL) isSuccessorTo: (Card *) other; // Move to Game logic: these methods are
- (BOOL) isPlayableOn: (Card *) other;  // not part of a generic card class.

@end
