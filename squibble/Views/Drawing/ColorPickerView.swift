//
//  ColorPickerView.swift
//  squibble
//
//  Color picker popover for drawing colors
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) var dismiss

    // Preset colors in a playful palette
    let colors: [Color] = [
        Color(hex: "2D2D2D"),  // Dark gray (almost black)
        Color(hex: "FF6B6B"),  // Coral red
        Color(hex: "FF8E53"),  // Orange
        Color(hex: "FFD93D"),  // Yellow
        Color(hex: "6BCB77"),  // Green
        Color(hex: "4D96FF"),  // Blue
        Color(hex: "9B59B6"),  // Purple
        Color(hex: "FF69B4"),  // Pink
        Color(hex: "8B4513"),  // Brown
        Color(hex: "FFFFFF"),  // White
    ]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Pick a Color")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(Color(hex: "2D2D2D"))

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "CCCCCC"))
                }
            }

            // Color grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    ColorDot(
                        color: color,
                        isSelected: selectedColor == color,
                        action: {
                            selectedColor = color
                            dismiss()
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

struct ColorDot: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 48, height: 48)
                }

                // Color circle
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "E0E0E0"), lineWidth: color == Color(hex: "FFFFFF") ? 1 : 0)
                    )

                // Checkmark for selected
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color == Color(hex: "FFFFFF") || color == Color(hex: "FFD93D") ? Color(hex: "2D2D2D") : .white)
                }
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ColorPickerView(selectedColor: .constant(Color(hex: "FF6B6B")))
        .padding()
        .background(Color(hex: "F5F5F5"))
}
