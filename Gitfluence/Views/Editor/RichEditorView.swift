import SwiftUI
import WebKit

struct RichEditorView: NSViewRepresentable {
    @Binding var markdown: String

    func makeCoordinator() -> EditorCoordinator { EditorCoordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeEditorWebView(coordinator: context.coordinator)

        context.coordinator.onMarkdownChange = { [weak ctx = context.coordinator] md in
            ctx?.markdown = md
            // Propagate to binding on main actor (already @MainActor)
            DispatchQueue.main.async { self.markdown = md }
        }

        loadBundle(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coord = context.coordinator
        // Only push to JS when the Swift side changed it (not echoing back JS changes)
        guard markdown != coord.lastReportedMarkdown else { return }
        coord.loadDocument(markdown)
        coord.lastReportedMarkdown = markdown
    }

    // MARK: -

    private func loadBundle(into webView: WKWebView) {
        webView.load(URLRequest(url: EditorSchemeHandler.richEditorURL()))
    }
}
