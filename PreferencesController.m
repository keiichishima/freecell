//
//  PreferencesController.m
//  Freecell
//
//  Created by Alisdair McDiarmid on Fri Aug 1 2003.
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

#import "PreferencesController.h"

@implementation PreferencesController

- (void) setCardSizeFromSliderValue: (double) sliderValue
{
    double scale = 0.5 + sliderValue / 100.0;
    CardView *view = [CardView cardView];
    NSSize size = NSMakeSize(95 * scale, 140 * scale);

    [view setCardSize: size];
    [self.gameView setCardView: view];
}

- (void) awakeFromNib
{
    NSData *data;
    double cardSize;
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.defaults registerDefaults:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool: YES], @"gameSuperMove",
            [NSNumber numberWithBool: YES], @"gameAutoStack",
            [NSNumber numberWithDouble: 50.0], @"gameCardSize",
            nil]];
    
    [self.autoStack setState: [self.defaults boolForKey: @"gameAutoStack"]];

    [self.superMove setState: [self.defaults boolForKey: @"gameSuperMove"]];

    cardSize = [self.defaults doubleForKey: @"gameCardSize"];
    [self.cardSizeSlider setDoubleValue: cardSize];
    [self setCardSizeFromSliderValue: cardSize];

    data = [self.defaults dataForKey: @"backgroundColour"];
    if (data)
    {
        NSColor *colour = [NSUnarchiver unarchiveObjectWithData: data];
        [self.backgroundColour setColor: colour];
    }
}

- (IBAction) openWindow: (id) sender
{
    [self.window makeKeyAndOrderFront: self];
}

- (IBAction) autoStackClicked: (id) sender
{
    NSNumber *state = [NSNumber numberWithBool: [self.autoStack state] == NSOnState];
    [self.defaults setObject: state forKey: @"gameAutoStack"];
}

- (IBAction) superMoveClicked: (id) sender
{
    NSNumber *state = [NSNumber numberWithBool: [self.superMove state] == NSOnState];
    [self.defaults setObject: state forKey: @"gameSuperMove"];
}

- (IBAction) cardSizeChanged: (id) sender
{
    double cardSize = [self.cardSizeSlider doubleValue];

    [self.defaults setObject: [NSNumber numberWithDouble: cardSize] forKey: @"gameCardSize"];
    [self setCardSizeFromSliderValue: cardSize];
}


- (IBAction) backgroundColourChosen: (id) sender
{
    NSColor *colour = [self.backgroundColour color];
    [self.defaults setObject: [NSArchiver archivedDataWithRootObject: colour] forKey: @"backgroundColour"];
    [self.gameView setBackgroundColour: colour];
}

@end
