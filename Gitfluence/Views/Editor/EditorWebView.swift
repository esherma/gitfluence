import SwiftUI
import WebKit

// ─── Shared bridge name ───────────────────────────────────────────────────────
let kEditorBridgeName = "editorBridge"

// ─── Editor bridge protocol ───────────────────────────────────────────────────
// All JS-side calls live under window.gitfluence.*

// ─── Base coordinator ─────────────────────────────────────────────────────────
// Both rich and source editors share this coordinator for the JS → Swift bridge.

@MainActor
final class EditorCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    // Markdown binding shared with the parent SwiftUI view
    var markdown: String = ""
    var onMarkdownChange: ((String) -> Void)?
    var onReady: (() -> Void)?

    // Track what the editor last reported so we avoid echo updates
    var lastReportedMarkdown: String = ""
    // Pending load requested before the editor was ready
    var pendingLoad: String? = nil
    var isReady = false

    weak var webView: WKWebView?

    // MARK: - WKScriptMessageHandler

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task { @MainActor in
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }
            switch type {
            case "ready":
                self.isReady = true
                if let pending = self.pendingLoad {
                    self.pendingLoad = nil
                    self.callLoadDocument(pending)
                }
                self.onReady?()

            case "contentChanged":
                if let md = body["markdown"] as? String {
                    self.lastReportedMarkdown = md
                    self.onMarkdownChange?(md)
                }

            default:
                break
            }
        }
    }

    // MARK: - WKNavigationDelegate

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // The page loaded; the JS will fire "ready" once the editor initialises.
    }

    // MARK: - JS calls

    func loadDocument(_ markdown: String) {
        if isReady {
            callLoadDocument(markdown)
        } else {
            pendingLoad = markdown
        }
    }

    func getMarkdown(completion: @escaping (String) -> Void) {
        guard let webView else { completion(""); return }
        webView.callAsyncJavaScript(
            "return window.gitfluence?.getMarkdown() ?? ''",
            arguments: [:],
            in: nil,
            in: .page
        ) { result in
            if case .success(let value) = result, let md = value as? String {
                completion(md)
            } else {
                completion("")
            }
        }
    }

    // MARK: - Private

    private func callLoadDocument(_ markdown: String) {
        guard let webView else { return }
        lastReportedMarkdown = markdown
        webView.callAsyncJavaScript(
            "window.gitfluence?.loadDocument(markdown)",
            arguments: ["markdown": markdown],
            in: nil,
            in: .page,
            completionHandler: nil
        )
    }
}

// ─── Shared WKWebView factory ─────────────────────────────────────────────────

@MainActor
func makeEditorWebView(coordinator: EditorCoordinator) -> WKWebView {
    let webView = makeGitfluenceWebView(messageHandler: coordinator)
    webView.navigationDelegate = coordinator
    coordinator.webView = webView
    return webView
}
