//
//  HelpController.m
//  Freecell
//
//  Copyright 2026 Keiichi SHIMA
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.

#import "HelpController.h"

@implementation HelpController

- (void)awakeFromNib
{
    [window setDelegate:self];
    
    // Allocate WKWebView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    CGRect frame = [[window contentView] bounds];
    webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
    webView.navigationDelegate = self;
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

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated &&
        url != nil &&
        !url.fileURL) {
        [[NSWorkspace sharedWorkspace] openURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
