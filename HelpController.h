//
//  HelpController.h
//  Freecell
//
//  Created by Keiichi SHIMA on 2026/06/27.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HelpController : NSObject <NSWindowDelegate>
{
    IBOutlet NSWindow *window;
    WKWebView *webView;
}

- (IBAction)openWindow:(id)sender;

@end

NS_ASSUME_NONNULL_END
