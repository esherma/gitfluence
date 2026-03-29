import WebKit

/// Shared helper that creates a WKWebView wired up to the gitfluence-editor://
/// scheme handler and the "editorBridge" message channel. Used by both the
/// editor views and the diff viewer.
@MainActor
func makeGitfluenceWebView(messageHandler: WKScriptMessageHandler) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.userContentController.add(
        WeakScriptMessageHandler(messageHandler),
        name: kEditorBridgeName
    )
    config.setURLSchemeHandler(EditorSchemeHandler(), forURLScheme: EditorSchemeHandler.scheme)
    return WKWebView(frame: .zero, configuration: config)
}

// ─── Weak wrapper ─────────────────────────────────────────────────────────────
// Breaks the retain cycle between WKUserContentController and the coordinator.

final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
