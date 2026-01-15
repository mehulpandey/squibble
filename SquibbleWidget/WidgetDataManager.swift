//
//  WidgetDataManager.swift
//  SquibbleWidget
//
//  Reads doodle data from shared App Group storage
//

import Foundation
import UIKit

struct WidgetDataManager {
    private static let suiteName = "group.mehulpandey.squibble"
    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Keys (must match AppGroupStorage in main app)

    private enum Keys {
        static let latestDoodleImagePath = "latestDoodleImagePath"
        static let latestDoodleSenderName = "latestDoodleSenderName"
        static let latestDoodleSenderInitials = "latestDoodleSenderInitials"
        static let latestDoodleSenderColor = "latestDoodleSenderColor"
        static let latestDoodleID = "latestDoodleID"
        static let latestDoodleDate = "latestDoodleDate"
        static let lastWidgetUpdate = "lastWidgetUpdate"
    }

    // MARK: - Read Latest Doodle

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

    static func getLastWidgetUpdate() -> Date? {
        userDefaults?.object(forKey: Keys.lastWidgetUpdate) as? Date
    }
}
