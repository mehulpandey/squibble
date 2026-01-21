//
//  Theme.swift
//  squibble
//
//  Centralized dark cinematic theme colors and styling
//

import SwiftUI

// MARK: - App Theme Colors

struct AppTheme {
    // MARK: - Background Colors
    static let backgroundTop = Color(hex: "16161f")
    static let backgroundBottom = Color(hex: "0d0d12")

    // Ambient glow colors (very subtle)
    static let ambientCoralGlow = Color(hex: "FF6B54").opacity(0.08)
    static let ambientOrangeGlow = Color(hex: "FF9F43").opacity(0.06)

    // MARK: - Primary Accent (Coral/Orange)
    static let primaryStart = Color(hex: "FF6B54")
    static let primaryEnd = Color(hex: "FF8F47")
    static let primaryGlow = Color(hex: "FF6B54").opacity(0.4)
    static let primaryGlowSoft = Color(hex: "FF6B54").opacity(0.3)

    // MARK: - Secondary Accent (Mustard Yellow)
    static let secondary = Color(hex: "F3B527")
    static let secondaryGlow = Color(hex: "F3B527").opacity(0.4)
    static let secondaryBackground = Color(hex: "F3B527").opacity(0.15)

    // MARK: - Glass-morphism Container
    static let glassBackground = Color.white.opacity(0.05)
    static let glassBackgroundStrong = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.08)
    static let glassBorderLight = Color.white.opacity(0.1)
    static let glassHighlight = Color.white.opacity(0.05)

    // MARK: - Drawing Canvas
    static let canvasTop = Color(hex: "1e1e2a")
    static let canvasBottom = Color(hex: "16161f")
    static let canvasBorder = Color.white.opacity(0.06)

    // MARK: - Button Colors
    static let buttonInactiveBackground = Color.white.opacity(0.06)
    static let buttonInactiveBorder = Color.white.opacity(0.08)
    static let buttonInactiveText = Color.white.opacity(0.5)
    static let buttonInactiveTextStrong = Color.white.opacity(0.6)

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.5)
    static let textInactive = Color.white.opacity(0.4)

    // MARK: - Modal Colors
    static let modalOverlay = Color.black.opacity(0.7)
    static let modalBackground = Color(hex: "1e1e2a")
    static let modalBackgroundBottom = Color(hex: "16161f")
    static let modalBorder = Color.white.opacity(0.1)
    static let modalHandle = Color.white.opacity(0.2)

    // MARK: - Divider
    static let divider = Color.white.opacity(0.08)

    // MARK: - Legacy compatibility (can remove later)
    static let coral = primaryStart
    static let coralDark = primaryEnd
    static let success = Color(hex: "F3B527")
    static let error = Color(hex: "FF6B54")
}

// MARK: - Gradients

extension AppTheme {
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryStart, primaryEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [canvasTop, canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var glassGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var modalGradient: LinearGradient {
        LinearGradient(
            colors: [modalBackground, modalBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Typography

struct AppTypography {
    static let displayFont = "Avenir-Black"
    static let headingFont = "Avenir-Heavy"
    static let bodyFont = "Avenir-Medium"
    static let captionFont = "Avenir-Regular"
}

// MARK: - Shadows

struct AppShadows {
    static let primaryGlow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        AppTheme.primaryGlow,
        16,
        0,
        4
    )

    static let secondaryGlow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        AppTheme.secondaryGlow,
        16,
        0,
        4
    )

    static let subtleShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        Color.black.opacity(0.3),
        8,
        0,
        4
    )
}

// MARK: - View Modifiers

struct GlassContainer: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.glassGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.glassBorder, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.glassHighlight, lineWidth: 1)
                    .padding(1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            )
    }
}

extension View {
    func glassContainer(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassContainer(cornerRadius: cornerRadius))
    }
}

// MARK: - Ambient Background View

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            AppTheme.backgroundGradient

            // Coral ambient glow (upper area)
            RadialGradient(
                colors: [AppTheme.ambientCoralGlow, .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 400
            )

            // Orange ambient glow (lower area)
            RadialGradient(
                colors: [AppTheme.ambientOrangeGlow, .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
    }
}
