//
//  NotificationService.swift
//  NotificationService
//
//  Intercepts push notifications to update widget with new doodle images
//

import UserNotifications
import WidgetKit

class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    private static let appGroupID = "group.mehulpandey.squibble"
    private static let widgetKind = "SquibbleWidget"

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let userInfo = content.userInfo

        // Only process new_doodle notifications with an image URL
        guard let type = userInfo["type"] as? String, type == "new_doodle",
              let imageURLString = userInfo["image_url"] as? String,
              let imageURL = URL(string: imageURLString) else {
            contentHandler(content)
            return
        }

        // Extract metadata from payload
        let senderName = userInfo["sender_name"] as? String ?? "Someone"
        let senderColorHex = userInfo["sender_color_hex"] as? String ?? "#FF6B54"
        let doodleIDString = userInfo["doodle_id"] as? String
        let senderInitials = Self.computeInitials(from: senderName)

        // Download image and update widget
        let task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            defer { contentHandler(content) }

            guard self != nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }

            // Write to App Group (same format as AppGroupStorage in main app)
            Self.saveToAppGroup(
                imageData: data,
                doodleID: doodleIDString,
                senderName: senderName,
                senderInitials: senderInitials,
                senderColor: senderColorHex
            )

            // Trigger widget refresh
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
        }
        task.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        // Deliver the notification as-is if we run out of time
        if let contentHandler = contentHandler,
           let content = bestAttemptContent {
            contentHandler(content)
        }
    }

    // MARK: - App Group Storage (mirrors AppGroupStorage.saveLatestDoodle)

    private static func saveToAppGroup(
        imageData: Data,
        doodleID: String?,
        senderName: String,
        senderInitials: String,
        senderColor: String
    ) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let defaults = UserDefaults(suiteName: appGroupID)

        // Save image file
        let imagePath = containerURL.appendingPathComponent("latest_doodle.png")
        try? imageData.write(to: imagePath)

        // Save metadata (keys must match AppGroupStorage.Keys exactly)
        defaults?.set(imagePath.path, forKey: "latestDoodleImagePath")
        defaults?.set(senderName, forKey: "latestDoodleSenderName")
        defaults?.set(senderInitials, forKey: "latestDoodleSenderInitials")
        defaults?.set(senderColor, forKey: "latestDoodleSenderColor")
        if let doodleID = doodleID {
            defaults?.set(doodleID, forKey: "latestDoodleID")
        }
        defaults?.set(Date(), forKey: "latestDoodleDate")
        defaults?.set(Date(), forKey: "lastWidgetUpdate")
    }

    // MARK: - Initials (mirrors User.initials)

    private static func computeInitials(from displayName: String) -> String {
        let components = displayName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}
