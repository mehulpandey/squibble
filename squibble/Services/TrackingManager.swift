//
//  TrackingManager.swift
//  squibble
//
//  Manages App Tracking Transparency for personalized ads
//

import AppTrackingTransparency
import GoogleMobileAds

/// Manages App Tracking Transparency (ATT) permission for personalized advertising
class TrackingManager {
    static let shared = TrackingManager()

    private init() {}

    /// Returns true if tracking is authorized (personalized ads allowed)
    var isTrackingAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    /// Requests tracking authorization from the user and updates AdMob configuration
    /// Must be called after app becomes active (Apple requirement)
    func requestTrackingPermission() async {
        // Only request if status is not determined
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            await ATTrackingManager.requestTrackingAuthorization()
        }

        // Update AdMob privacy configuration based on tracking status
        updateAdMobPrivacyConfiguration()
    }

    /// Updates AdMob to use personalized or non-personalized ads based on tracking status
    private func updateAdMobPrivacyConfiguration() {
        if isTrackingAuthorized {
            MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .enabled
        } else {
            MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        }
    }
}
