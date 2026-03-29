import SwiftUI
import WebKit

// ─── SwiftUI wrapper ──────────────────────────────────────────────────────────

struct DiffView: NSViewRepresentable {
    let diff: String
    var comments: [PRComment] = []
    var onCommentRequest: ((String, Int, String) -> Void)?

    func makeCoordinator() -> DiffCoordinator {
        DiffCoordinator(onCommentRequest: onCommentRequest)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeGitfluenceWebView(messageHandler: context.coordinator)
        context.coordinator.webView = webView
        webView.load(URLRequest(url: EditorSchemeHandler.diffViewerURL()))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coord = context.coordinator
        if diff != coord.lastDiff {
            coord.loadDiff(diff)
        }
        if comments != coord.lastComments {
            coord.loadComments(comments)
        }
    }
}

// ─── Coordinator ──────────────────────────────────────────────────────────────

@MainActor
final class DiffCoordinator: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    var lastDiff: String = ""
    var lastComments: [PRComment] = []
    var onCommentRequest: ((String, Int, String) -> Void)?
    private var isReady = false
    private var pendingDiff: String?

    init(onCommentRequest: ((String, Int, String) -> Void)?) {
        self.onCommentRequest = onCommentRequest
    }

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
                if let pending = self.pendingDiff {
                    self.pendingDiff = nil
                    self.callLoadDiff(pending)
                }
            case "commentRequest":
                let path = body["filePath"] as? String ?? ""
                let line = body["lineNumber"] as? Int ?? 0
                let side = body["side"] as? String ?? "RIGHT"
                self.onCommentRequest?(path, line, side)
            default:
                break
            }
        }
    }

    func loadDiff(_ diff: String) {
        lastDiff = diff
        if isReady { callLoadDiff(diff) } else { pendingDiff = diff }
    }

    func loadComments(_ comments: [PRComment]) {
        lastComments = comments
        guard isReady, !comments.isEmpty else { return }
        guard let data = try? JSONEncoder().encode(comments),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.callAsyncJavaScript(
            "window.gitfluence?.loadComments(commentsJson)",
            arguments: ["commentsJson": json],
            in: nil, in: .page, completionHandler: nil
        )
    }

    func appendComment(_ comment: PRComment) {
        lastComments.append(comment)
        guard isReady,
              let data = try? JSONEncoder().encode(comment),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.callAsyncJavaScript(
            "window.gitfluence?.appendComment(commentJson)",
            arguments: ["commentJson": json],
            in: nil, in: .page, completionHandler: nil
        )
    }

    private func callLoadDiff(_ diff: String) {
        webView?.callAsyncJavaScript(
            "window.gitfluence?.loadDiff(diff)",
            arguments: ["diff": diff],
            in: nil, in: .page, completionHandler: nil
        )
    }
}
