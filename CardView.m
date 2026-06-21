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

#import <AppKit/AppKit.h>
#import "CardView.h"

@implementation CardView

+ cardView
{
    return [[[CardView alloc] init] autorelease];
}

- init
{
    [super init];
    
    svgCache = [[NSMutableDictionary alloc] init];
    
    // デフォルトのカードサイズ（初期値）
    cardSize = NSMakeSize(95, 140);
    NSLog(@"CardView: initialized with cardSize: %.0f x %.0f", cardSize.width, cardSize.height);
    
    [self drawBlanks];
    NSLog(@"CardView: drawBlanks completed");
    [self drawCards];
    NSLog(@"CardView: drawCards completed - cards count: %lu", [cards count]);
    [self drawSelectedCards];
    NSLog(@"CardView: drawSelectedCards completed");
    
    return self;
}

// MARK: - SVG Image Handling
// 注意: 将来的にウインドウのスケーリング対応を行う際は、以下の手順を実行してください:
// 1. setCardSize: メソッドを実装
// 2. svgCacheをクリア
// 3. drawBlanks, drawCards, drawSelectedCards を再実行
//
// 現在の実装では、SVG画像をNSImageとしてロードし、指定されたカードサイズで
// ラスタライズしています。SVGはベクトル形式であるため、異なるサイズでの
// レンダリングに対応可能な構造になっています。

- (NSString *) svgFilenameForCard: (Card *) card
{
    NSString *rankStr;
    NSString *suitStr;
    
    // ランク文字列をマッピング
    switch ([card rank]) {
        case ACE: rankStr = @"ace"; break;
        case TWO: rankStr = @"2"; break;
        case THREE: rankStr = @"3"; break;
        case FOUR: rankStr = @"4"; break;
        case FIVE: rankStr = @"5"; break;
        case SIX: rankStr = @"6"; break;
        case SEVEN: rankStr = @"7"; break;
        case EIGHT: rankStr = @"8"; break;
        case NINE: rankStr = @"9"; break;
        case TEN: rankStr = @"10"; break;
        case JACK: rankStr = @"jack"; break;
        case QUEEN: rankStr = @"queen"; break;
        case KING: rankStr = @"king"; break;
        default: rankStr = @"unknown"; break;
    }
    
    // スーツ文字列を小文字に変換
    suitStr = [[card suitString] lowercaseString];
    
    return [NSString stringWithFormat: @"%@_of_%@", rankStr, suitStr];
}

- (NSImage *) svgImageForCard: (Card *) card
{
    if (card == nil)
        return nil;
    
    // キャッシュから取得
    NSString *filename = [self svgFilenameForCard: card];
    NSImage *cachedImage = [svgCache objectForKey: filename];
    if (cachedImage != nil) {
        return cachedImage;
    }
    
    // SVGファイルを読み込む
    NSString *svgPath = [[NSBundle mainBundle] pathForResource: filename 
                                                        ofType: @"svg"];
    
    if (svgPath == nil) {
        NSLog(@"SVG file not found: %@.svg", filename);
        return nil;
    }
    
    NSLog(@"Loading SVG from path: %@", svgPath);
    NSImage *image = [[NSImage alloc] initWithContentsOfFile: svgPath];
    if (image == nil) {
        NSLog(@"Failed to load SVG: %@", svgPath);
        return nil;
    }
    
    // SVG画像の representations を確認
    NSArray *representations = [image representations];
    NSLog(@"SVG loaded: %@, representations: %@", filename, [representations class]);
    for (NSImageRep *rep in representations) {
        NSLog(@"  - %@ (size: %.0f x %.0f)", [rep class], [rep size].width, [rep size].height);
    }
    
    // キャッシュに保存
    [svgCache setObject: image forKey: filename];
    [image release];
    
    return [svgCache objectForKey: filename];
}

- (void) drawBlanks
{
    // SVGベースの空白カード（無地の背景）
    blank = [[NSImage alloc] initWithSize: cardSize];
    [blank lockFocus];
    
    // 白い背景
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect: NSMakeRect(0, 0, cardSize.width, cardSize.height)];
    
    // 黒い枠線
    [[NSColor blackColor] set];
    [NSBezierPath strokeRect: NSMakeRect(0.5, 0.5, cardSize.width - 1, cardSize.height - 1)];
    
    [blank unlockFocus];
    
    // Selected blank (半透明オーバーレイ用)
    selectedBlank = [[NSImage alloc] initWithSize: cardSize];
    [selectedBlank lockFocus];
    
    // 灰色の半透明背景
    [[NSColor colorWithDeviceRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.3] set];
    [NSBezierPath fillRect: NSMakeRect(0, 0, cardSize.width, cardSize.height)];
    
    [selectedBlank unlockFocus];
}

- (void) drawCards
{
    NSMutableDictionary *dict;
    unsigned i;
    
    NSLog(@"CardView: drawCards started");
    dict = [NSMutableDictionary dictionaryWithCapacity: 52];
    for (i = 0; i < NUMBER_OF_SUITS; i++)
    {
        unsigned j;
        for (j = ACE; j <= KING; j++)
        {
            Card *cardObj = [Card cardWithSuit: i rank: j];
            NSImage *svgImage = [self svgImageForCard: cardObj];
            
            if (svgImage == nil) {
                NSLog(@"Failed to load SVG for card: suit=%d rank=%d", i, j);
                continue;
            }
            
            // 正しいサイズでビットマップに描画
            NSImage *scaledCard = [[NSImage alloc] initWithSize: cardSize];
            [scaledCard lockFocus];
            
            // 白い背景
            [[NSColor whiteColor] set];
            NSRectFill(NSMakeRect(0, 0, cardSize.width, cardSize.height));
            
            // SVGを正しいサイズで描画
            [svgImage drawInRect: NSMakeRect(0, 0, cardSize.width, cardSize.height)
                       fromRect: NSZeroRect
                      operation: NSCompositeSourceOver
                       fraction: 1.0];
            
            // 黒い枠線
            [[NSColor blackColor] set];
            [NSBezierPath strokeRect: NSMakeRect(0.5, 0.5, cardSize.width - 1, cardSize.height - 1)];
            
            [scaledCard unlockFocus];
            
            [dict setObject: scaledCard forKey: cardObj];
            [scaledCard release];
        }
    }
    
    cards = [dict retain];
    NSLog(@"CardView: drawCards completed - cards count: %lu", [cards count]);
}

- (void) drawSelectedCards
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 52];
    Card *card;
    NSEnumerator *enumerator = [cards keyEnumerator];

    while (card = [enumerator nextObject])
    {
        NSImage *image = [[cards objectForKey: card] copy];
        [image lockFocus];
        
        // 半透明の灰色オーバーレイを描画
        [[NSColor colorWithDeviceRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.3] set];
        [NSBezierPath fillRect: NSMakeRect(0, 0, cardSize.width, cardSize.height)];
        
        [image unlockFocus];
        [dict setObject: image forKey: card];
        [image release];
    }
    selectedCards = [dict retain];
}


- (NSImage *) imageForCard: (Card *) card selected: (BOOL) isSelected
{
    if (card == nil)
        return isSelected? selectedBlank: blank;
    
    return [isSelected? selectedCards: cards objectForKey: card];
}

- (NSSize) size
{
    return cardSize;
}

- (void) setCardSize: (NSSize) newSize
{
    // 将来的なスケーリング対応用メソッド
    // ウインドウサイズの変更に応じて、カードサイズを変更する場合に使用します。
    if (NSEqualSizes(newSize, cardSize))
        return;  // 変更なし
    
    cardSize = newSize;
    
    // SVGキャッシュをクリア
    [svgCache removeAllObjects];
    
    // カード画像を再描画
    [self drawBlanks];
    [self drawCards];
    [self drawSelectedCards];
}

- (unsigned) overlap
{
    return cardSize.height/3;
}

- (unsigned) smallOverlap
{
    return cardSize.height/4.75;
}

@end
