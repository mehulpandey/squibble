//
//  MoreOptionsSheet.swift
//  squibble
//
//  More options menu for canvas customization
//

import SwiftUI
import PhotosUI

struct MoreOptionsSheet: View {
    @ObservedObject var drawingState: DrawingState
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss

    let onShowUpgrade: () -> Void

    @State private var showBackgroundColorPicker = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    private var isPremium: Bool {
        userManager.currentUser?.isPremium ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("More Options")
                    .font(.custom("Avenir-Heavy", size: 20))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Options list
            VStack(spacing: 0) {
                // Background color option (free)
                optionRow(
                    icon: "paintpalette.fill",
                    iconColor: Color(hex: "A78BFA"),
                    title: "Background Color",
                    subtitle: "Change canvas background",
                    isPremiumOnly: false,
                    action: {
                        showBackgroundColorPicker = true
                    }
                )

                Divider()
                    .background(AppTheme.divider)
                    .padding(.horizontal, 20)

                // Upload image option (premium)
                optionRow(
                    icon: "photo.fill",
                    iconColor: Color(hex: "38BDF8"),
                    title: "Upload Image",
                    subtitle: "Doodle on top of a photo",
                    isPremiumOnly: true,
                    action: {
                        if isPremium {
                            showPhotoPicker = true
                        } else {
                            dismiss()
                            onShowUpgrade()
                        }
                    }
                )

                Divider()
                    .background(AppTheme.divider)
                    .padding(.horizontal, 20)

                // AI Animation option (premium, coming soon)
                optionRow(
                    icon: "wand.and.stars",
                    iconColor: Color(hex: "FFD93D"),
                    title: "Animate with AI",
                    subtitle: "Bring your doodle to life",
                    isPremiumOnly: true,
                    isComingSoon: true,
                    action: { }
                )
            }
            .glassContainer(cornerRadius: 16)
            .padding(.horizontal, 20)

            Spacer()
        }
        .sheet(isPresented: $showBackgroundColorPicker) {
            BackgroundColorPickerSheet(
                selectedColor: $drawingState.canvasBackgroundColor
            )
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.modalGradient)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newValue in
            if let newValue {
                loadImage(from: newValue)
            }
        }
    }

    private func optionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isPremiumOnly: Bool,
        isComingSoon: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("Avenir-Heavy", size: 16))
                            .foregroundColor(isComingSoon ? AppTheme.textTertiary : AppTheme.textPrimary)

                        if isPremiumOnly && !isPremium {
                            premiumBadge
                        }

                        if isComingSoon {
                            Text("SOON")
                                .font(.custom("Avenir-Heavy", size: 9))
                                .foregroundColor(Color(hex: "FFD93D"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "FFD93D").opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.custom("Avenir-Regular", size: 13))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()

                // Chevron
                if !isComingSoon {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isComingSoon)
    }

    private var premiumBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("PRO")
                .font(.custom("Avenir-Heavy", size: 9))
        }
        .foregroundColor(Color(hex: "FFD93D"))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(hex: "FFD93D").opacity(0.2))
        .cornerRadius(4)
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }
            await MainActor.run {
                drawingState.backgroundImage = uiImage
                dismiss()
            }
        }
    }
}

// MARK: - Background Color Picker Sheet

struct BackgroundColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) var dismiss

    // Canvas background colors (same palette as drawing colors)
    let colors: [Color] = [
        // Row 1 - Neutrals
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

    private var selectedHex: String {
        selectedColor.toHex()
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Background Color")
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
                    BackgroundColorDot(
                        color: color,
                        isSelected: color.toHex() == selectedHex,
                        action: {
                            selectedColor = color
                            dismiss()
                        }
                    )
                }
            }
        }
        .padding(24)
    }
}

struct BackgroundColorDot: View {
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
                                color.toHex() == "FFFFFF" || color.toHex() == "FAF5F0"
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
    MoreOptionsSheet(
        drawingState: DrawingState(),
        onShowUpgrade: { }
    )
    .environmentObject(UserManager())
    .presentationBackground(AppTheme.modalGradient)
}
