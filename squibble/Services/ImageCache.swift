//
//  ImageCache.swift
//  squibble
//
//  Simple image caching service for doodle thumbnails
//

import Foundation
import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private var cache = NSCache<NSString, UIImage>()
    private var downloadTasks: [String: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 100
    }

    func image(for urlString: String) async -> UIImage? {
        // Check cache first
        if let cached = cache.object(forKey: urlString as NSString) {
            return cached
        }

        // Check if already downloading
        if let existingTask = downloadTasks[urlString] {
            return await existingTask.value
        }

        // Start download
        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString) else { return nil }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }

                // Cache the image
                cache.setObject(image, forKey: urlString as NSString)
                return image
            } catch {
                print("Image download failed: \(error)")
                return nil
            }
        }

        downloadTasks[urlString] = task
        let result = await task.value
        downloadTasks.removeValue(forKey: urlString)

        return result
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    func removeImage(for urlString: String) {
        cache.removeObject(forKey: urlString as NSString)
    }
}
