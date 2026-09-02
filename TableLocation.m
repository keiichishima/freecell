//
//  TableLocation.m
//  Freecell
//
//  Created by Alisdair McDiarmid on Thu Jul 24 2003.
//  Copyright (c) 2003 Alisdair McDiarmid.
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

#import "TableLocation.h"

@implementation TableLocation

+ (instancetype)locationWithType:(TableLocationType)newType number:(NSUInteger)newNumber {
    return [[TableLocation alloc] initWithType:newType number:newNumber];
}

+ (instancetype)noLocation {
    return [[TableLocation alloc] initWithType:TableLocationTypeNone number:0];
}

- (instancetype)initWithType:(TableLocationType)newType number:(NSUInteger)newNumber {
    self = [super init];

    if (self) {
        _type = newType;
        _number = newNumber;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[TableLocation allocWithZone:zone] initWithType:self.type number:self.number];
}

// Overridden methods
//

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[TableLocation class]]) return NO;

    TableLocation *other = (TableLocation *)object;
    return (self.type == other.type && self.number == other.number);
}

- (NSString *)description {
    NSString *typeToString[] = {@"None", @"Free Cell", @"Stack", @"Column", @"Deck"};

    return [NSString stringWithFormat:@"%@:%lu", typeToString[self.type], self.number];
}

@end
