import WebKit

/// Custom URL scheme handler for `gitfluence-editor://`.
/// Serves files from the app bundle, sidestepping file:// permission
/// issues that arise with ad-hoc code signing + WKWebView.
///
/// URL format:  gitfluence-editor://<bundle-subfolder>/<path>
/// Example:     gitfluence-editor://RichEditor/index.html
///              gitfluence-editor://RichEditor/assets/index-ABC123.js
final class EditorSchemeHandler: NSObject, WKURLSchemeHandler {

    static let scheme = "gitfluence-editor"

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        let url = urlSchemeTask.request.url!
        // url.host = bundle subfolder (e.g. "RichEditor")
        // url.path = "/assets/index-xxx.js" or "/index.html"
        let subfolder  = url.host ?? ""
        let filePath   = url.path  // starts with "/"

        guard
            let resourceURL = Bundle.main.url(
                forResource: "index",
                withExtension: "html",
                subdirectory: subfolder
            )?.deletingLastPathComponent()
        else {
            urlSchemeTask.didFailWithError(
                NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist)
            )
            return
        }

        // Build the full path: <bundle>/Resources/<subfolder>/<filePath>
        let fileURL = resourceURL.appendingPathComponent(
            filePath.hasPrefix("/") ? String(filePath.dropFirst()) : filePath
        )

        guard
            let data = try? Data(contentsOf: fileURL)
        else {
            urlSchemeTask.didFailWithError(
                NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist)
            )
            return
        }

        let mimeType = Self.mimeType(for: fileURL.pathExtension)
        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: mimeType.contains("text") || mimeType.contains("javascript") || mimeType.contains("json")
                ? "utf-8" : nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}

    // MARK: - MIME type helpers

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html":       return "text/html"
        case "js", "mjs":  return "application/javascript"
        case "css":        return "text/css"
        case "json":       return "application/json"
        case "woff2":      return "font/woff2"
        case "woff":       return "font/woff"
        case "ttf":        return "font/ttf"
        case "svg":        return "image/svg+xml"
        case "png":        return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        default:           return "application/octet-stream"
        }
    }
}

// MARK: - Convenience URL builders

extension EditorSchemeHandler {
    static func richEditorURL() -> URL {
        URL(string: "\(scheme)://RichEditor/index.html")!
    }
    static func sourceEditorURL() -> URL {
        URL(string: "\(scheme)://SourceEditor/index.html")!
    }
}
