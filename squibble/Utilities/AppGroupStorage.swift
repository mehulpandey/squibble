//
//  AppGroupStorage.swift
//  squibble
//
//  Shared storage utility for widget communication via App Group
//

import Foundation
import UIKit

struct AppGroupStorage {
    private static let suiteName = Config.appGroupIdentifier
    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // Widget kind constant - must match SquibbleWidget.kind
    static let widgetKind = "SquibbleWidget"

    // MARK: - Keys

    private enum Keys {
        static let latestDoodleImagePath = "latestDoodleImagePath"
        static let latestDoodleSenderName = "latestDoodleSenderName"
        static let latestDoodleSenderInitials = "latestDoodleSenderInitials"
        static let latestDoodleSenderColor = "latestDoodleSenderColor"
        static let latestDoodleID = "latestDoodleID"
        static let latestDoodleDate = "latestDoodleDate"
        static let lastWidgetUpdate = "lastWidgetUpdate"
    }

    // MARK: - Latest Doodle for Widget

    static func saveLatestDoodle(
        imageData: Data,
        doodleID: UUID,
        senderName: String,
        senderInitials: String,
        senderColor: String,
        date: Date
    ) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        ) else { return }

        // Save image to shared container
        let imagePath = containerURL.appendingPathComponent("latest_doodle.png")
        try? imageData.write(to: imagePath)

        // Save metadata
        userDefaults?.set(imagePath.path, forKey: Keys.latestDoodleImagePath)
        userDefaults?.set(senderName, forKey: Keys.latestDoodleSenderName)
        userDefaults?.set(senderInitials, forKey: Keys.latestDoodleSenderInitials)
        userDefaults?.set(senderColor, forKey: Keys.latestDoodleSenderColor)
        userDefaults?.set(doodleID.uuidString, forKey: Keys.latestDoodleID)
        userDefaults?.set(date, forKey: Keys.latestDoodleDate)
        userDefaults?.set(Date(), forKey: Keys.lastWidgetUpdate)
    }

    static func getLastWidgetUpdate() -> Date? {
        userDefaults?.object(forKey: Keys.lastWidgetUpdate) as? Date
    }

    static func getLatestDoodleImage() -> UIImage? {
        guard let path = userDefaults?.string(forKey: Keys.latestDoodleImagePath) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }

    static func getLatestDoodleMetadata() -> (senderName: String, initials: String, color: String, doodleID: UUID?, date: Date?)? {
        guard let name = userDefaults?.string(forKey: Keys.latestDoodleSenderName),
              let initials = userDefaults?.string(forKey: Keys.latestDoodleSenderInitials),
              let color = userDefaults?.string(forKey: Keys.latestDoodleSenderColor) else {
            return nil
        }

        let doodleIDString = userDefaults?.string(forKey: Keys.latestDoodleID)
        let doodleID = doodleIDString.flatMap { UUID(uuidString: $0) }
        let date = userDefaults?.object(forKey: Keys.latestDoodleDate) as? Date

        return (name, initials, color, doodleID, date)
    }

    static func clearLatestDoodle() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        ) else { return }

        let imagePath = containerURL.appendingPathComponent("latest_doodle.png")
        try? FileManager.default.removeItem(at: imagePath)

        userDefaults?.removeObject(forKey: Keys.latestDoodleImagePath)
        userDefaults?.removeObject(forKey: Keys.latestDoodleSenderName)
        userDefaults?.removeObject(forKey: Keys.latestDoodleSenderInitials)
        userDefaults?.removeObject(forKey: Keys.latestDoodleSenderColor)
        userDefaults?.removeObject(forKey: Keys.latestDoodleID)
        userDefaults?.removeObject(forKey: Keys.latestDoodleDate)
    }
}
