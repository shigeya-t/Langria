import UIKit
import WebKit

/// Reads the text of a page shared only as a URL (by apps other than Safari,
/// which hand over the page itself). It loads the page in an invisible web
/// view, with no cookies or storage kept, and runs Preprocess.js on it as
/// Safari would.
@MainActor
final class PageReader: NSObject, WKNavigationDelegate {
  /// How long to wait for the page to finish loading before reading what is there.
  static let timeout: Duration = .seconds(15)

  private let webView: WKWebView
  private var loaded: CheckedContinuation<Void, Never>?

  init(in view: UIView) {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    webView = WKWebView(frame: view.bounds, configuration: configuration)
    super.init()
    webView.navigationDelegate = self
    // In the hierarchy (behind the sheet) so the page lays out and runs as if shown.
    webView.alpha = 0
    webView.isUserInteractionEnabled = false
    view.insertSubview(webView, at: 0)
  }

  /// The page's main text, or nil when it could not be read.
  func text(at url: URL) async -> String? {
    defer { webView.stopLoading(); webView.removeFromSuperview() }
    guard let script = Bundle.main.url(forResource: "Preprocess", withExtension: "js").flatMap({ try? String(contentsOf: $0, encoding: .utf8) }) else { return nil }
    webView.load(URLRequest(url: url))
    await withCheckedContinuation { continuation in
      loaded = continuation
      Task { [weak self] in
        try? await Task.sleep(for: Self.timeout)
        self?.finish()
      }
    }
    let body = script + "\nreturn await new Promise(function (resolve) { ExtensionPreprocessingJS.run({ completionFunction: resolve }); });"
    for attempt in 0..<2 {
      // Pages that build their content with scripts may not have it yet at the load event.
      if attempt > 0 { try? await Task.sleep(for: .seconds(1.5)) }
      let result = try? await webView.callAsyncJavaScript(body, contentWorld: .defaultClient) as? [String: Any]
      let text = (result?["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if text.count >= 200 || (attempt > 0 && !text.isEmpty) { return text }
    }
    return nil
  }

  private func finish() {
    loaded?.resume()
    loaded = nil
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finish() }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finish() }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finish() }

  /// Stays on the web: a link to another app or a download is not followed.
  func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
    ["http", "https"].contains(action.request.url?.scheme?.lowercased() ?? "") ? .allow : .cancel
  }
}
