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

- (NSSize)windowSizeForSliderValue:(double)sliderValue {
    double scale = 0.5 + sliderValue / 100.0;
    CardView *view = [CardView cardView];
    view.cardSize = NSMakeSize(95 * scale, 140 * scale);
    return [GameView windowSizeForCardView:view];
}

- (void)setCardSizeSliderValue:(double)sliderValue {
    sliderValue = MAX(self.cardSizeSlider.minValue, MIN(self.cardSizeSlider.maxValue, sliderValue));
    [self.cardSizeSlider setDoubleValue:sliderValue];
    [self.defaults setDouble:sliderValue forKey:@"gameCardSize"];
    [self setCardSizeFromSliderValue:sliderValue];
}

- (void)setCardSizeFromSliderValue:(double)sliderValue {
    double scale = 0.5 + sliderValue / 100.0;
    CardView *view = [CardView cardView];
    NSSize size = NSMakeSize(95 * scale, 140 * scale);

    [view setCardSize:size];
    [self.gameView setCardView:view];
}

- (void)previewCardSizeSliderValue:(double)sliderValue {
    double scale = 0.5 + sliderValue / 100.0;
    CardView *view = [CardView cardView];
    view.cardSize = NSMakeSize(95 * scale, 140 * scale);
    [self.gameView setCardViewWithoutResizingWindow:view];
}

- (void)awakeFromNib {
    NSData *data;
    double cardSize;

    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.defaults registerDefaults:@{ @"gameSuperMove" : @YES, @"gameAutoStack" : @YES, @"gameCardSize" : @50.0 }];

    [self.autoStack setState:[self.defaults boolForKey:@"gameAutoStack"] ? NSControlStateValueOn : NSControlStateValueOff];

    [self.superMove setState:[self.defaults boolForKey:@"gameSuperMove"] ? NSControlStateValueOn : NSControlStateValueOff];

    NSWindow *gameWindow = self.gameView.window;
    NSSize maxSize = gameWindow.maxSize;
    double minimum = self.cardSizeSlider.minValue;
    double maximum = self.cardSizeSlider.maxValue;
    for (int i = 0; i < 40; i++) {
        double value = (minimum + maximum) / 2.0;
        NSSize size = [self windowSizeForSliderValue:value];
        if (size.width <= maxSize.width && size.height <= maxSize.height)
            minimum = value;
        else
            maximum = value;
    }
    self.cardSizeSlider.maxValue = minimum;
    gameWindow.minSize = [self windowSizeForSliderValue:self.cardSizeSlider.minValue];

    cardSize = [self.defaults doubleForKey:@"gameCardSize"];
    [self setCardSizeSliderValue:cardSize];

    data = [self.defaults dataForKey:@"backgroundColour"];
    if (data) {
        NSColor *colour = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:data error:nil];
        if (colour) [self.backgroundColour setColor:colour];
    }
}

- (IBAction)openWindow:(id)sender {
    [self.window makeKeyAndOrderFront:self];
}

- (IBAction)autoStackClicked:(id)sender {
    [self.defaults setBool:([self.autoStack state] == NSControlStateValueOn) forKey:@"gameAutoStack"];
}

- (IBAction)superMoveClicked:(id)sender {
    [self.defaults setBool:([self.superMove state] == NSControlStateValueOn) forKey:@"gameSuperMove"];
}

- (IBAction)cardSizeChanged:(id)sender {
    [self setCardSizeSliderValue:self.cardSizeSlider.doubleValue];
}

- (IBAction)backgroundColourChosen:(id)sender {
    NSColor *colour = [self.backgroundColour color];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:colour requiringSecureCoding:YES error:nil];
    if (data) [self.defaults setObject:data forKey:@"backgroundColour"];
    [self.gameView setBackgroundColour:colour];
}

@end
