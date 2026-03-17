import SwiftUI
import WebKit

struct SourceEditorView: NSViewRepresentable {
    @Binding var markdown: String

    func makeCoordinator() -> EditorCoordinator { EditorCoordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeEditorWebView(coordinator: context.coordinator)

        context.coordinator.onMarkdownChange = { md in
            DispatchQueue.main.async { self.markdown = md }
        }

        loadBundle(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coord = context.coordinator
        guard markdown != coord.lastReportedMarkdown else { return }
        coord.loadDocument(markdown)
        coord.lastReportedMarkdown = markdown
    }

    // MARK: -

    private func loadBundle(into webView: WKWebView) {
        webView.load(URLRequest(url: EditorSchemeHandler.sourceEditorURL()))
    }
}
