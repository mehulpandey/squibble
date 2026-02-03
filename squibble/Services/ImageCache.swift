//
//  ImageCache.swift
//  squibble
//
//  Image caching service with both memory and disk layers to minimize network egress
//

import Foundation
import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private var memoryCache = NSCache<NSString, UIImage>()
    private var downloadTasks: [String: Task<UIImage?, Never>] = [:]
    private let diskCacheURL: URL?

    /// Max disk cache size in bytes (50 MB)
    private let maxDiskCacheSize: Int = 50 * 1024 * 1024

    private init() {
        memoryCache.countLimit = 100

        // Set up disk cache directory
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let dir = caches.appendingPathComponent("ImageCache", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            diskCacheURL = dir
        } else {
            diskCacheURL = nil
        }
    }

    func image(for urlString: String) async -> UIImage? {
        // 1. Check memory cache
        if let cached = memoryCache.object(forKey: urlString as NSString) {
            return cached
        }

        // 2. Check disk cache
        if let diskImage = loadFromDisk(urlString: urlString) {
            memoryCache.setObject(diskImage, forKey: urlString as NSString)
            return diskImage
        }

        // 3. Check if already downloading
        if let existingTask = downloadTasks[urlString] {
            return await existingTask.value
        }

        // 4. Start download
        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString) else { return nil }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }

                // Save to both caches
                memoryCache.setObject(image, forKey: urlString as NSString)
                saveToDisk(data: data, urlString: urlString)
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
        memoryCache.removeAllObjects()
        if let dir = diskCacheURL {
            try? FileManager.default.removeItem(at: dir)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func removeImage(for urlString: String) {
        memoryCache.removeObject(forKey: urlString as NSString)
        if let path = diskPath(for: urlString) {
            try? FileManager.default.removeItem(at: path)
        }
    }

    // MARK: - Disk Cache Helpers

    private func diskPath(for urlString: String) -> URL? {
        guard let dir = diskCacheURL else { return nil }
        // Use a hash of the URL as the filename to avoid path issues
        let filename = String(urlString.hashValue, radix: 36, uppercase: false)
        return dir.appendingPathComponent(filename)
    }

    private func loadFromDisk(urlString: String) -> UIImage? {
        guard let path = diskPath(for: urlString),
              FileManager.default.fileExists(atPath: path.path) else { return nil }
        // Touch the access date so LRU eviction works
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: path.path
        )
        return UIImage(contentsOfFile: path.path)
    }

    private func saveToDisk(data: Data, urlString: String) {
        guard let path = diskPath(for: urlString) else { return }
        try? data.write(to: path, options: .atomic)
        evictIfNeeded()
    }

    // MARK: - Cache Eviction

    /// Removes oldest files when disk cache exceeds maxDiskCacheSize
    private func evictIfNeeded() {
        guard let dir = diskCacheURL else { return }

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        // Calculate total size and collect file info
        var totalSize: Int = 0
        var fileInfos: [(url: URL, size: Int, modified: Date)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize,
                  let modified = values.contentModificationDate else { continue }
            totalSize += size
            fileInfos.append((url: file, size: size, modified: modified))
        }

        guard totalSize > maxDiskCacheSize else { return }

        // Sort oldest first, delete until under limit
        fileInfos.sort { $0.modified < $1.modified }

        for info in fileInfos {
            guard totalSize > maxDiskCacheSize else { break }
            try? fm.removeItem(at: info.url)
            totalSize -= info.size
        }
    }
}
