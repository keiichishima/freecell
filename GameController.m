//
//  GameController.m
//  Freecell
//
//
//  Created by Alisdair McDiarmid on Tue Jul 08 2003.
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

#import "GameController.h"
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

@interface GameController (PrivateMethods)

- (void)GC_startGame;
- (void)GC_stopTimer;

@end

@implementation GameController

// Overridden methods
//

- (void)awakeFromNib {
    [super awakeFromNib];
    srandom((unsigned int)time(NULL));

    if (self.history != nil) [self.history awakeFromNib];
    [self updateTime:self.timer];
    [self moveMade];

    [self.window setReleasedWhenClosed:NO];
    [self.window setMiniwindowTitle:@"Freecell"];

    [self.view setController:self];
    [self newGame:self];
    self.timer = nil;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)flag {
    if (flag == NO) [self newGame:self];

    return YES;
}

- (BOOL)windowShouldClose:(id)sender {
    if (self.game.inProgress == NO) {
        [self setGame:nil];
        return YES;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"closeTitle", @"windowShouldClose sheet title")];
    [alert setInformativeText:NSLocalizedString(@"closeText", @"windowShouldClose sheet text")];
    [alert addButtonWithTitle:NSLocalizedString(@"closeButton", @"Close button")];
    [alert addButtonWithTitle:NSLocalizedString(@"cancelButton", @"Cancel button")];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      if (returnCode == NSAlertFirstButtonReturn) [self.window close];
                  }];

    return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(id)sender {
    if (self.game.inProgress == NO) return NSTerminateNow;

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"closeTitle", @"windowShouldClose sheet title")];
    [alert setInformativeText:NSLocalizedString(@"closeText", @"windowShouldClose sheet text")];
    [alert addButtonWithTitle:NSLocalizedString(@"closeButton", @"Close button")];
    [alert addButtonWithTitle:NSLocalizedString(@"cancelButton", @"Cancel button")];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      [self.window close];
                      [NSApp replyToApplicationShouldTerminate:(returnCode == NSAlertFirstButtonReturn)];
                  }];

    return NSTerminateLater;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem tag] == 1) return [self.game canUndo];
    if ([menuItem tag] == 2) return [self.game canRedo];

    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([[notification object] isEqual:self.window]) [self setGame:nil];
}

// Action methods
//

- (IBAction)newGame:(id)sender {
    [self playGameWithNumber:[NSNumber numberWithDouble:(double)random()]];
}

- (IBAction)retryGame:(id)sender {
    [self GC_startGame];
}

- (IBAction)playGameNumber:(id)sender {
    if ([self.gameNumberField doubleValue] <= 0) {
        NSBeep();
        [self.gameNumberField selectText:self];
        return;
    }

    [self GC_startGame];
}

- (IBAction)openPlayNumberDialog:(id)sender {
    NSNumberFormatter *formatter = (NSNumberFormatter *)[self.gameNumberField formatter];
    if ([formatter isKindOfClass:[NSNumberFormatter class]]) {
        [formatter setAllowsFloats:NO];
        [formatter setMinimum:[NSNumber numberWithInt:1]];
    }

    if ([self.window attachedSheet] == nil) {
        [self.window beginSheet:self.playNumberDialog completionHandler:nil];
        [self.gameNumberField selectText:self];
    }
}

- (IBAction)closePlayNumberDialog:(id)sender {
    [self.window endSheet:self.playNumberDialog];
    [self.playNumberDialog orderOut:self];
    [self.playNumberDialog close];
}

- (IBAction)showHint:(id)sender {
    [self.game setHint];
    if ([self.game hint]) {
        [self.view setNeedsDisplay:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.game setHint:nil];
            [self.view setNeedsDisplay:YES];
        });
    }
}

- (IBAction)undo:(id)sender {
    [self.game undo];
}

- (IBAction)redo:(id)sender {
    [self.game redo];
}

// Private methods
//

- (void)GC_startGame {
    if ([self.window attachedSheet] != nil) {
        // Clear up the you-won/you-lost dialog if it's open
        if (self.game.inProgress == NO) {
            [NSApp endSheet:[self.window attachedSheet]];
            [NSApp stopModal];
        }
        // Otherwise, we must already be checking whether or not to end the game
        else
            return;
    }

    if (self.game.inProgress == YES) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"newGameTitle", @"New game sheet title")];
        [alert setInformativeText:NSLocalizedString(@"newGameText", @"New game sheet text")];
        [alert addButtonWithTitle:NSLocalizedString(@"newGameButton", @"New game button")];
        [alert addButtonWithTitle:NSLocalizedString(@"cancelButton", @"Cancel button")];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse returnCode) {
                          if (returnCode == NSAlertFirstButtonReturn) {
                              self.game = nil;
                              [self GC_startGame];
                          }
                      }];
    } else {
        NSNumber *gameNumber = [NSNumber numberWithDouble:[self.gameNumberField doubleValue]];

        self.game = [Game gameWithView:self.view controller:self gameNumber:gameNumber];
        [self.view setGame:self.game];

        [self.window setTitle:[NSString stringWithFormat:NSLocalizedString(@"gameWindowTitleFormat",
                                                                           @"Format for the title of the game window"),
                                                         [self.gameNumberField stringValue]]];
        [self.window makeKeyAndOrderFront:self];
        [self.window makeMainWindow];

        [self GC_stopTimer];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(updateTime:)
                                                    userInfo:nil
                                                     repeats:YES];
        [self updateTime:self.timer];
        [self moveMade];
    }
}

- (void)GC_stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

// Timer stuff
//

- (void)updateTime:(NSTimer *)sender {
    NSDate *current = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    NSDate *shortest = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *currentDuration;
    NSString *shortestDuration;

    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    if (self.game.inProgress) {
        current =
            [NSDate dateWithTimeIntervalSinceReferenceDate:[[NSDate date] timeIntervalSinceDate:[self.game startDate]]];
    } else if (![[self.game result] isEqual:[Result resultWithUnplayed]]) {
        NSTimeInterval duration = [self.game duration];
        current = [NSDate dateWithTimeIntervalSinceReferenceDate:duration];
    }
    currentDuration = [formatter stringFromDate:current];
    if (self.history) shortest = [self.history shortestDuration];
    shortestDuration = [formatter stringFromDate:shortest];

    if (self.game != nil)
        [self.timeElapsed
            setStringValue:[NSString stringWithFormat:@"%@ (%@ %@)", currentDuration,
                                                      NSLocalizedString(@"bestIs", "best is"), shortestDuration]];
}

- (void)moveMade {
    NSUInteger currentMoves = [self.game moves];
    NSUInteger shortestMoves = [self.history shortestMoves];
    [self.movesMade setStringValue:[NSString stringWithFormat:@"%lu %@ (%@ %lu)", currentMoves,
                                                              NSLocalizedString(@"moves", "moves"),
                                                              NSLocalizedString(@"bestIs", "best is"), shortestMoves]];
}

// Mutators
//

- (void)playGameWithNumber:(NSNumber *)newGame {
    [self.gameNumberField setDoubleValue:[newGame doubleValue]];
    [self GC_startGame];
}

- (void)setWindowSize:(NSSize)size {
    NSRect frame = [self.window frame];
    frame.size = size;
    [self.window setFrame:frame display:YES];
}

- (void)recordGame {
    [self.history addRecordWithGameNumber:[self.game gameNumber]
                                   result:[self.game result]
                                    moves:[self.game moves]
                                 duration:[self.game duration]
                                     date:[self.game startDate]];
}

- (void)setGame:(Game *)newGame {
    [self GC_stopTimer];

    if (_game.inProgress) [_game gameOverWithResult:[Result resultWithLoss]];

    if ([[_game result] isEqual:[Result resultWithWin]] || [[_game result] isEqual:[Result resultWithLoss]])
        [self recordGame];

    _game = newGame;
}

- (void)gameOver {
    NSString *title, *defaultButton, *alternateButton, *message;
    Result *result = [self.game result];

    [self.timer fire];

    [self GC_stopTimer];

    if ([result isEqual:[Result resultWithWin]]) {
        title = NSLocalizedString(@"wonTitle", @"Won sheet title");
        defaultButton = NSLocalizedString(@"wonDefaultButton", @"Won sheet default button");
        alternateButton = NSLocalizedString(@"showHistoryButton", @"Show history button");
        message = [NSString stringWithFormat:NSLocalizedString(@"wonText", @"Won sheet text"), [self.game moves]];
    } else if ([result isEqual:[Result resultWithLoss]]) {
        title = NSLocalizedString(@"lostTitle", @"Lost sheet title");
        defaultButton = NSLocalizedString(@"lostDefaultButton", @"Lost sheet default button");
        alternateButton = NSLocalizedString(@"retryGameButton", @"Retry game button");
        message = [NSString stringWithFormat:NSLocalizedString(@"lostText", @"Lost sheet text"), [self.game moves]];
    } else {
        return;
    }
    [self recordGame];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:defaultButton];
    [alert addButtonWithTitle:alternateButton];
    [alert addButtonWithTitle:NSLocalizedString(@"newGameButton", @"New game button")];

    if ([result isEqual:[Result resultWithWin]]) {
        [alert beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse returnCode) {
                          if (returnCode == NSAlertSecondButtonReturn) [self.history openWindow:self];
                          if (returnCode == NSAlertThirdButtonReturn) [self newGame:self];
                      }];
    } else if ([result isEqual:[Result resultWithLoss]]) {
        [alert beginSheetModalForWindow:self.window
                      completionHandler:^(NSModalResponse returnCode) {
                          if (returnCode == NSAlertSecondButtonReturn) [self retryGame:self];
                          if (returnCode == NSAlertThirdButtonReturn) [self newGame:self];
                      }];
    }
}

@end
