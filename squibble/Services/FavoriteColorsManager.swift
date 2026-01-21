//
//  FavoriteColorsManager.swift
//  squibble
//
//  Manages persistent storage of user's 5 favorite drawing colors
//

import SwiftUI
import Combine

class FavoriteColorsManager: ObservableObject {
    static let shared = FavoriteColorsManager()

    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "favoriteDrawingColors"

    // Default favorite colors (diverse selection from color picker)
    private let defaultColors: [String] = [
        "EF4444",  // Red
        "F97316",  // Orange
        "4ADE80",  // Green
        "3B82F6",  // Blue
        "8B5CF6"   // Purple
    ]

    @Published var favoriteColors: [Color] = []

    private init() {
        loadFavorites()
    }

    private func loadFavorites() {
        if let savedHexes = userDefaults.array(forKey: favoritesKey) as? [String], savedHexes.count == 5 {
            favoriteColors = savedHexes.map { Color(hex: $0) }
        } else {
            // Use defaults
            favoriteColors = defaultColors.map { Color(hex: $0) }
            saveFavorites()
        }
    }

    private func saveFavorites() {
        let hexStrings = favoriteColors.map { $0.toHex() }
        userDefaults.set(hexStrings, forKey: favoritesKey)
    }

    func updateFavorite(at index: Int, with color: Color) {
        guard index >= 0 && index < 5 else { return }
        favoriteColors[index] = color
        saveFavorites()
    }

    func getFavorite(at index: Int) -> Color {
        guard index >= 0 && index < favoriteColors.count else {
            return Color(hex: defaultColors[0])
        }
        return favoriteColors[index]
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
