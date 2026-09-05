//
//  HistoryController.m
//  Freecell
//
//  Created by Alisdair McDiarmid on Tue Jul 29 2003.
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

#import "HistoryController.h"
#import "GameController.h"

@interface HistoryController (PrivateMethods)

- (void)HC_updateWindow;
- (void)HC_sortTable;
- (void)HC_setSortColumn:(NSString *)newSortColumn;
- (NSImage *)HC_sortDescendingToImage;
- (void)HC_setDateFormat;

@end

@implementation HistoryController

// Overridden methods
//

- (void)awakeFromNib {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *file = [@"~/Library/Preferences/org.wasters.Freecell.history.plist" stringByExpandingTildeInPath];
    self.history = [[History alloc] initWithFile:file];

    [self.tableView setDataSource:self.history];
    [self.tableView setAutosaveName:@"history"];
    [self.tableView setAutosaveTableColumns:YES];
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(retryGame:)];

    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:@"date", @"historySortColumn",
                                                                          [NSNumber numberWithBool:YES],
                                                                          @"historySortDescending", nil]];

    self.sortColumn = [defaults stringForKey:@"historySortColumn"];
    self.sortDescending = [defaults boolForKey:@"historySortDescending"];
    [self HC_sortTable];

    [self HC_setDateFormat];

    [self HC_updateWindow];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([self.tableView selectedRow] == -1)
        [self.retryGame setEnabled:NO];
    else
        [self.retryGame setEnabled:YES];
}

- (void)tableView:(NSTableView *)newTableView didClickTableColumn:(NSTableColumn *)column {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([self.sortColumn isEqualToString:[column identifier]])
        self.sortDescending = !self.sortDescending;
    else {
        [self.tableView setIndicatorImage:nil inTableColumn:[self.tableView tableColumnWithIdentifier:self.sortColumn]];
        self.sortDescending = NO;
    }

    self.sortColumn = [column identifier];
    [self HC_sortTable];

    [defaults setObject:self.sortColumn forKey:@"historySortColumn"];
    [defaults setObject:[NSNumber numberWithBool:self.sortDescending] forKey:@"historySortDescending"];
}

// Private methods
//

- (void)HC_updateWindow {
    unsigned won = [self.history numberOfRecordsWithResult:[Result resultWithWin]];
    unsigned lost = [self.history numberOfRecordsWithResult:[Result resultWithLoss]];
    unsigned wonPercent = (unsigned)floor(((double)won * 100.0) / (won + lost));
    unsigned lostPercent = 100 - wonPercent;

    if (won + lost == 0) wonPercent = lostPercent = 0.0;

    [self.gamesPlayed setIntValue:won + lost];
    [self.gamesWon setStringValue:[NSString stringWithFormat:@"%d (%d%%)", won, wonPercent]];
    [self.gamesLost setStringValue:[NSString stringWithFormat:@"%d (%d%%)", lost, lostPercent]];

    [self.tableView noteNumberOfRowsChanged];
    [self.tableView setNeedsDisplay:YES];
}

- (void)HC_sortTable {
    NSImage *sortImage = [self HC_sortDescendingToImage];
    NSTableColumn *column = [self.tableView tableColumnWithIdentifier:self.sortColumn];

    [self.tableView setIndicatorImage:sortImage inTableColumn:column];
    [self.tableView setHighlightedTableColumn:column];

    [self.history sortByColumn:self.sortColumn withDescending:self.sortDescending];
    [self.tableView reloadData];
}

- (NSImage *)HC_sortDescendingToImage {
    if (self.sortDescending)
        return [NSImage imageNamed:@"NSDescendingSortIndicator"];
    else
        return [NSImage imageNamed:@"NSAscendingSortIndicator"];
}

- (void)HC_setDateFormat {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    [[self.lastPlayedColumn dataCell] setFormatter:formatter];
}

// Action methods
//

- (IBAction)clear:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"cancelButton", @"Cancel button")];
    [alert addButtonWithTitle:NSLocalizedString(@"clearButton", @"Clear history button")];
    [alert setMessageText:NSLocalizedString(@"clearTitle", @"Clear history sheet title")];
    [alert setInformativeText:NSLocalizedString(@"clearText", @"Clear history sheet text")];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
                      if (returnCode == NSAlertSecondButtonReturn) {
                          [self.history clear];
                          [self HC_updateWindow];
                      }
                  }];
}

- (IBAction)openWindow:(id)sender {
    [self.window makeKeyAndOrderFront:self];
}

- (IBAction)retryGame:(id)sender {
    NSInteger row = [self.tableView selectedRow];

    // Ignore double-clicks on the TableView if they are on a column header
    if (sender == self.tableView && [self.tableView clickedRow] == -1) return;

    if (row != -1) {
        [self.gameController playGameWithNumber:[self.history gameNumberForRecord:row]];
        [self.window close];
    }
}

// Mutators
//

- (void)addRecordWithGameNumber:(NSNumber *)gameNumber
                         result:(Result *)result
                          moves:(unsigned short)moves
                       duration:(NSTimeInterval)duration
                           date:(NSDate *)date {
    [self.history addRecordWithGameNumber:gameNumber result:result moves:moves duration:duration date:date];
    [self HC_sortTable];
    [self HC_updateWindow];
}

- (NSDate *)shortestDuration {
    return [self.history shortestDuration];
}

- (unsigned)shortestMoves {
    return [self.history shortestMoves];
}

- (unsigned)numberOfGamesWon {
    return [self.history numberOfRecordsWithResult:[Result resultWithWin]];
}

@end
