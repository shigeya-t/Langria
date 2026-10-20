import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI
import UserMessagingPlatform

/// Asks for consent (UMP, then App Tracking Transparency) and starts the
/// Mobile Ads SDK once ads may be requested.
@MainActor
final class Ads: ObservableObject {
  /// True once consent allows ad requests and the SDK has started.
  @Published private(set) var ready = false
  /// Some consent messages (GDPR) need a way back to the choices, shown in the settings.
  @Published private(set) var privacyOptionsRequired = false
  private var gathering = false

  /// The banner unit for this build: Google's test unit in Debug (project.yml).
  static let bannerUnitID = Bundle.main.object(forInfoDictionaryKey: "LangriaBannerUnitID") as? String ?? ""

  // The unit tests run inside the app; they should not reach the network for ads.
  private static let disabled = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

  /// Runs on every launch while the app is active, as consent can expire and
  /// the forms and the tracking prompt are only shown to an active app.
  func gatherConsent() async {
    guard !Self.disabled, !gathering, !ready else { return }
    gathering = true
    defer { gathering = false }
    let consent = ConsentInformation.shared
    // On failure the choices from an earlier launch still apply: carry on and check canRequestAds.
    try? await consent.requestConsentInfoUpdate(with: RequestParameters())
    try? await ConsentForm.loadAndPresentIfRequired(from: nil)
    privacyOptionsRequired = consent.privacyOptionsRequirementStatus == .required
    // UMP shows the tracking prompt itself when an IDFA message is set up in AdMob; this covers the case without one.
    if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
      _ = await ATTrackingManager.requestTrackingAuthorization()
    }
    start()
  }

  func showPrivacyOptions() async {
    try? await ConsentForm.presentPrivacyOptionsForm(from: nil)
    start()
  }

  private func start() {
    guard !ready, ConsentInformation.shared.canRequestAds else { return }
    MobileAds.shared.start(completionHandler: nil)
    ready = true
  }
}

/// An anchored adaptive banner across the full width. It takes no room until
/// an ad arrives, nor while hidden, which keeps the ad rather than loading a new one.
struct BannerAd: View {
  var hidden = false
  @State private var width: CGFloat = 0
  @State private var loaded = false

  var body: some View {
    let size = largeAnchoredAdaptiveBanner(width: width)
    // Color.clear takes the full width offered, which an empty view would not.
    Color.clear
      .frame(height: loaded && !hidden ? size.size.height : 0)
      // Full size even while hidden: the SDK will not load into a zero-height view.
      .overlay(alignment: .top) {
        if width > 0 { BannerViewRepresentable(size: size, loaded: $loaded).frame(height: size.size.height) }
      }
      .clipped()
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
  }
}

private struct BannerViewRepresentable: UIViewRepresentable {
  let size: AdSize
  @Binding var loaded: Bool

  func makeUIView(context: Context) -> BannerView {
    let banner = BannerView(adSize: size)
    banner.adUnitID = Ads.bannerUnitID
    banner.delegate = context.coordinator
    banner.load(Request())
    return banner
  }

  // A new width (rotation, iPad split view) needs an ad of the new size.
  // Compared with the size asked for, as the loaded ad's own size can differ.
  func updateUIView(_ banner: BannerView, context: Context) {
    guard context.coordinator.requested.size != size.size else { return }
    context.coordinator.requested = size
    banner.adSize = size
    banner.load(Request())
  }

  func makeCoordinator() -> Coordinator { Coordinator(loaded: $loaded, requested: size) }

  final class Coordinator: NSObject, BannerViewDelegate {
    @Binding var loaded: Bool
    var requested: AdSize
    init(loaded: Binding<Bool>, requested: AdSize) { _loaded = loaded; self.requested = requested }
    func bannerViewDidReceiveAd(_ bannerView: BannerView) { loaded = true }
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) { loaded = false }
  }
}
