//
//  ExpandedColorPickerView.swift
//  squibble
//
//  Expanded color picker modal for selecting favorite colors
//

import SwiftUI

struct ExpandedColorPickerView: View {
    @Binding var selectedColor: Color
    let favoriteIndex: Int
    let onColorSelected: (Color, Int) -> Void
    @Environment(\.dismiss) var dismiss

    // Curated color palette (5 columns, 5 rows = 25 colors)
    let colors: [Color] = [
        // Row 1 - Neutrals (light to dark)
        Color(hex: "FFFFFF"), Color(hex: "FAF5F0"), Color(hex: "9CA3AF"), Color(hex: "374151"), Color(hex: "111827"),
        // Row 2 - Pinks & Reds
        Color(hex: "FECDD3"), Color(hex: "FCA5A5"), Color(hex: "FB7185"), Color(hex: "EF4444"), Color(hex: "BE123C"),
        // Row 3 - Yellows & Oranges
        Color(hex: "FEF3C7"), Color(hex: "FCD34D"), Color(hex: "FDBA74"), Color(hex: "F97316"), Color(hex: "C2410C"),
        // Row 4 - Greens & Teals
        Color(hex: "A7F3D0"), Color(hex: "4ADE80"), Color(hex: "2DD4BF"), Color(hex: "22D3EE"), Color(hex: "38BDF8"),
        // Row 5 - Blues & Purples
        Color(hex: "93C5FD"), Color(hex: "3B82F6"), Color(hex: "C4B5FD"), Color(hex: "A78BFA"), Color(hex: "8B5CF6"),
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    // Convert selected color to hex for comparison
    private var selectedHex: String {
        selectedColor.toHex()
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Choose Color")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            // Color grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    ExpandedColorDot(
                        color: color,
                        isSelected: color.toHex() == selectedHex,
                        action: {
                            selectedColor = color
                            onColorSelected(color, favoriteIndex)
                            dismiss()
                        }
                    )
                }
            }
        }
        .padding(24)
    }
}

struct ExpandedColorDot: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Color circle with glow effect
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .shadow(color: color.opacity(isSelected ? 0.6 : 0.3), radius: isSelected ? 8 : 4, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .stroke(
                                color.toHex() == "FFFFFF" || color.toHex() == "E0E0E0"
                                    ? AppTheme.glassBorder
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )

                // Selection ring (white border)
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.6), radius: 8, x: 0, y: 0)

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isLightColor(color) ? AppTheme.backgroundTop : .white)
                }
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func isLightColor(_ color: Color) -> Bool {
        let hex = color.toHex()
        // Light colors where checkmark should be dark
        return hex == "FFFFFF" || hex == "FAF5F0" || hex == "FECDD3" || hex == "FCA5A5" ||
               hex == "FEF3C7" || hex == "FCD34D" || hex == "FDBA74" || hex == "A7F3D0" ||
               hex == "4ADE80" || hex == "2DD4BF" || hex == "22D3EE" || hex == "38BDF8" ||
               hex == "93C5FD" || hex == "C4B5FD"
    }
}

#Preview {
    ExpandedColorPickerView(
        selectedColor: .constant(Color(hex: "FF6B54")),
        favoriteIndex: 0,
        onColorSelected: { _, _ in }
    )
    .presentationDetents([.height(420)])
    .presentationBackground(AppTheme.modalGradient)
}
