//
//  HelpController.m
//  Freecell
//
//  Created by Keiichi SHIMA on 2026/06/27.
//

#import "HelpController.h"

@implementation HelpController

- (void)awakeFromNib
{
    [window setDelegate:self];
    
    // Allocate WKWebView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    CGRect frame = [[window contentView] bounds];
    webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
    webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [[window contentView] addSubview:webView];
    
    [self loadHelpContent];
}

- (void)loadHelpContent
{
    // Retrieve Freecell.help bundle
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"Freecell" withExtension:@"help"];
    if (!bundleURL) {
        NSLog(@"Help bundle not found");
        return;
    }
    
    NSBundle *helpBundle = [NSBundle bundleWithURL:bundleURL];
    if (!helpBundle) {
        NSLog(@"Failed to load help bundle");
        return;
    }
    
    // Locate Freecell.html based on the current language
    NSURL *htmlURL = [helpBundle URLForResource:@"Freecell" withExtension:@"html"];
    if (!htmlURL) {
        NSLog(@"Help HTML not found");
        return;
    }
    
    // Load HTML to WebView
    NSURLRequest *request = [NSURLRequest requestWithURL:htmlURL];
    [webView loadRequest:request];
}

- (IBAction)openWindow:(id)sender
{
    [window makeKeyAndOrderFront:self];
}

- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

@end
