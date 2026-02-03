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

    @State private var selectedTab = 0
    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    @State private var hexInput: String = ""
    @FocusState private var isHexFocused: Bool

    // Fixed heights for consistent layout
    private let presetContentHeight: CGFloat = 304 // 5 rows * 48 + 4 gaps * 16
    private let customContentHeight: CGFloat = 160

    var body: some View {
        VStack(spacing: 0) {
            // Header - fixed position
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
            .padding(.bottom, 20)

            // Tab selector — lightweight pill toggle - fixed position
            HStack(spacing: 4) {
                tabButton(title: "Preset", index: 0)
                tabButton(title: "Custom", index: 1)
            }
            .padding(3)
            .background(AppTheme.glassBackground)
            .cornerRadius(10)
            .padding(.bottom, 20)

            // Tab content - fixed height container
            ZStack(alignment: .top) {
                if selectedTab == 0 {
                    presetGrid
                        .frame(height: presetContentHeight, alignment: .top)
                } else {
                    customPicker
                        .frame(height: presetContentHeight, alignment: .top)
                }
            }
        }
        .padding(24)
        .onAppear {
            initHSBFromColor(selectedColor)
            hexInput = customColor.toHex()
        }
    }

    // MARK: - Tab Button

    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.custom("Avenir-Heavy", size: 14))
                .foregroundColor(selectedTab == index ? .white : AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == index ? AppTheme.glassBackgroundStrong : Color.clear)
                .cornerRadius(8)
        }
    }

    // MARK: - Preset Grid

    private let colors: [Color] = [
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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    private var selectedHex: String {
        selectedColor.toHex()
    }

    private var presetGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
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

    // MARK: - Custom Picker

    private var customColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private var customPicker: some View {
        VStack(spacing: 16) {
            // Large saturation-brightness rectangle
            SaturationBrightnessView(
                hue: hue,
                saturation: $saturation,
                brightness: $brightness,
                onChange: { applyCustomColor(); updateHexFromHSB() }
            )
            .frame(height: 180)
            .cornerRadius(12)

            // Hue slider
            HueSlider(
                value: $hue,
                onChange: { applyCustomColor(); updateHexFromHSB() }
            )

            // Hex input field - right aligned
            HStack(spacing: 8) {
                Spacer()

                Text("Hex")
                    .font(.custom("Avenir-Heavy", size: 14))
                    .foregroundColor(AppTheme.textTertiary)

                HStack(spacing: 4) {
                    Text("#")
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(AppTheme.textTertiary)

                    TextField("FFFFFF", text: $hexInput)
                        .font(.custom("Avenir-Heavy", size: 14))
                        .foregroundColor(AppTheme.textPrimary)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isHexFocused)
                        .frame(width: 55)
                        .onChange(of: hexInput) { newValue in
                            // Limit to 6 characters and uppercase
                            let filtered = String(newValue.uppercased().filter { $0.isHexDigit }.prefix(6))
                            if filtered != hexInput {
                                hexInput = filtered
                            }
                            // Apply color when 6 valid hex chars entered
                            if filtered.count == 6 {
                                applyHexColor(filtered)
                            }
                        }
                        .onSubmit {
                            if hexInput.count == 6 {
                                applyHexColor(hexInput)
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.glassBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.glassBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Gradients

    private var hueGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: (0...10).map { Color(hue: Double($0) / 10.0, saturation: 1, brightness: 1) }),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var saturationGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0, brightness: brightness),
                Color(hue: hue, saturation: 1, brightness: brightness)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var brightnessGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: saturation, brightness: 0),
                Color(hue: hue, saturation: saturation, brightness: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Helpers

    private func initHSBFromColor(_ color: Color) {
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        hue = Double(h)
        saturation = Double(s)
        brightness = Double(b)
    }

    private func applyCustomColor() {
        let color = Color(hue: hue, saturation: saturation, brightness: brightness)
        selectedColor = color
        onColorSelected(color, favoriteIndex)
    }

    private func updateHexFromHSB() {
        hexInput = customColor.toHex()
    }

    private func applyHexColor(_ hex: String) {
        let color = Color(hex: hex)
        initHSBFromColor(color)
        selectedColor = color
        onColorSelected(color, favoriteIndex)
    }
}

// MARK: - Character Hex Check Extension

private extension Character {
    var isHexDigit: Bool {
        self.isNumber || ("A"..."F").contains(self) || ("a"..."f").contains(self)
    }
}

// MARK: - Saturation-Brightness 2D Picker

private struct SaturationBrightnessView: View {
    let hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double
    let onChange: () -> Void

    private let thumbSize: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Background gradient: saturation (left to right) + brightness (top to bottom)
                // First layer: white to hue color (saturation)
                LinearGradient(
                    colors: [.white, Color(hue: hue, saturation: 1, brightness: 1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Second layer: transparent to black (brightness)
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Thumb indicator
                Circle()
                    .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .position(
                        x: saturation * width,
                        y: (1 - brightness) * height
                    )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        saturation = Double(min(max(drag.location.x / width, 0), 1))
                        brightness = Double(min(max(1.0 - drag.location.y / height, 0), 1))
                        onChange()
                    }
            )
        }
    }
}

// MARK: - Hue Slider

private struct HueSlider: View {
    @Binding var value: Double
    let onChange: () -> Void

    private let trackHeight: CGFloat = 14
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let thumbX = value * trackWidth

            ZStack(alignment: .leading) {
                // Hue gradient track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: (0...10).map { Color(hue: Double($0) / 10.0, saturation: 1, brightness: 1) }),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: trackHeight)

                // Thumb
                Circle()
                    .fill(Color(hue: value, saturation: 1, brightness: 1))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .offset(x: thumbX - thumbSize / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let newValue = min(max(drag.location.x / trackWidth, 0), 1)
                        value = Double(newValue)
                        onChange()
                    }
            )
        }
        .frame(height: thumbSize)
    }
}

// MARK: - Labeled HSB Slider

private struct LabeledHSBSlider: View {
    let label: String
    @Binding var value: Double
    let gradient: LinearGradient
    let thumbColor: Color
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.custom("Avenir-Heavy", size: 12))
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 14)

            HSBSlider(
                value: $value,
                gradient: gradient,
                thumbColor: thumbColor,
                onChange: onChange
            )
        }
    }
}

// MARK: - HSB Gradient Slider

private struct HSBSlider: View {
    @Binding var value: Double
    let gradient: LinearGradient
    let thumbColor: Color
    let onChange: () -> Void

    private let trackHeight: CGFloat = 14
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let thumbX = value * trackWidth

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(gradient)
                    .frame(height: trackHeight)

                // Thumb
                Circle()
                    .fill(thumbColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .offset(x: thumbX - thumbSize / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let newValue = min(max(drag.location.x / trackWidth, 0), 1)
                        value = Double(newValue)
                        onChange()
                    }
            )
        }
        .frame(height: thumbSize)
    }
}

// MARK: - Expanded Color Dot

struct ExpandedColorDot: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
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

                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.6), radius: 8, x: 0, y: 0)

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
    .presentationDetents([.height(450)])
    .presentationBackground(AppTheme.modalGradient)
}
