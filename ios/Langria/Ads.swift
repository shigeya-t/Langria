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
  private static let disabled = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || Screenshots.enabled

  /// Runs each time the app becomes active, as the forms and the tracking
  /// prompt are only shown to an active app. Consent is checked once per
  /// launch, as UMP asks; a choice that expires is asked again on the next one.
  func gatherConsent() async {
    guard !Self.disabled, !gathering else { return }
    gathering = true
    defer { gathering = false }
    if !ready {
      let consent = ConsentInformation.shared
      // On failure the choices from an earlier launch still apply: carry on and check canRequestAds.
      try? await consent.requestConsentInfoUpdate(with: RequestParameters())
      try? await ConsentForm.loadAndPresentIfRequired(from: nil)
      privacyOptionsRequired = consent.privacyOptionsRequirementStatus == .required
    }
    await requestTracking()
    start()
  }

  /// UMP shows the tracking prompt itself when an IDFA message is set up in
  /// AdMob; this covers the case without one. Asked before the app is fully
  /// active, iOS returns without showing the prompt, so it is tried again
  /// (after a moment, and on the next activation) while still undecided.
  private func requestTracking() async {
    for _ in 0..<2 {
      guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
      if UIApplication.shared.applicationState == .active {
        _ = await ATTrackingManager.requestTrackingAuthorization()
      }
      try? await Task.sleep(for: .seconds(1))
    }
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

/// An inline adaptive banner across the width of the page. It takes no room until an ad arrives.
struct BannerAd: View {
  @Environment(\.scenePhase) private var scenePhase
  @State private var width: CGFloat = 0
  /// Set by the ad that arrives: an inline adaptive ad picks its own height.
  @State private var height: CGFloat = 0

  var body: some View {
    // Color.clear takes the full width offered, which an empty view would not.
    Color.clear
      .frame(height: height)
      // Given room even before an ad arrives: the SDK will not load into a zero-height view.
      .overlay(alignment: .top) {
        if width > 0 {
          BannerViewRepresentable(size: currentOrientationInlineAdaptiveBanner(width: width), active: scenePhase == .active, height: $height)
            .frame(height: max(height, AdSizeBanner.size.height))
        }
      }
      .clipped()
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
  }
}

private struct BannerViewRepresentable: UIViewRepresentable {
  let size: AdSize
  let active: Bool
  @Binding var height: CGFloat

  func makeUIView(context: Context) -> BannerView {
    let banner = BannerView(adSize: size)
    banner.adUnitID = Ads.bannerUnitID
    banner.delegate = context.coordinator
    banner.load(Request())
    return banner
  }

  // A new width (rotation, iPad split view) needs an ad of the new size.
  // Compared with the width asked for, as the loaded ad's own size differs.
  func updateUIView(_ banner: BannerView, context: Context) {
    let coordinator = context.coordinator
    let becameActive = active && !coordinator.active
    coordinator.active = active
    if coordinator.width != size.size.width {
      coordinator.width = size.size.width
      banner.adSize = size
      banner.load(Request())
    } else if becameActive && !coordinator.hasAd {
      // A load that failed (such as one made as the app left or came back
      // to the foreground) may not be tried again, and the banner would
      // otherwise stay empty until the next launch.
      banner.load(Request())
    }
  }

  func makeCoordinator() -> Coordinator { Coordinator(height: $height, width: size.size.width, active: active) }

  final class Coordinator: NSObject, BannerViewDelegate {
    @Binding var height: CGFloat
    var width: CGFloat
    var active: Bool
    /// Whether an ad is on show. A failed refresh leaves the last ad in place, so it stays visible.
    var hasAd = false
    init(height: Binding<CGFloat>, width: CGFloat, active: Bool) { _height = height; self.width = width; self.active = active }
    func bannerViewDidReceiveAd(_ bannerView: BannerView) { hasAd = true; height = bannerView.adSize.size.height }
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
      guard !hasAd else { return }
      height = 0
    }
  }
}
