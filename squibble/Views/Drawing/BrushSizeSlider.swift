//
//  BrushSizeSlider.swift
//  squibble
//
//  Brush size slider popover
//

import SwiftUI

struct BrushSizeSlider: View {
    @Binding var lineWidth: CGFloat
    @Environment(\.dismiss) var dismiss

    // Local state to avoid continuous objectWillChange on DrawingState during drag
    @State private var localWidth: CGFloat = 8

    let minWidth: CGFloat = 2
    let maxWidth: CGFloat = 20

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Brush Size")
                    .font(.custom("Avenir-Heavy", size: 18))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.top, 4)

            // Preview dot
            Circle()
                .fill(AppTheme.textPrimary)
                .frame(width: localWidth * 2, height: localWidth * 2)
                .frame(height: 40)

            // Slider
            HStack(spacing: 16) {
                // Small dot
                Circle()
                    .fill(AppTheme.textTertiary)
                    .frame(width: 8, height: 8)

                // Custom slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(AppTheme.glassBackgroundStrong)
                            .frame(height: 6)

                        // Filled portion
                        Capsule()
                            .fill(AppTheme.primaryGradient)
                            .frame(width: thumbPosition(in: geometry.size.width), height: 6)

                        // Thumb
                        Circle()
                            .fill(AppTheme.glassBackgroundStrong)
                            .frame(width: 24, height: 24)
                            .shadow(color: AppTheme.primaryGlow, radius: 6, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .fill(AppTheme.primaryGradient)
                                    .frame(width: 12, height: 12)
                            )
                            .offset(x: thumbPosition(in: geometry.size.width) - 12)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let percent = min(max(0, value.location.x / geometry.size.width), 1)
                                        localWidth = minWidth + (maxWidth - minWidth) * percent
                                    }
                                    .onEnded { _ in
                                        lineWidth = localWidth
                                    }
                            )
                    }
                }
                .frame(height: 24)

                // Large dot
                Circle()
                    .fill(AppTheme.textTertiary)
                    .frame(width: 16, height: 16)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onAppear {
            localWidth = lineWidth
        }
        .onDisappear {
            lineWidth = localWidth
        }
    }

    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let percent = (localWidth - minWidth) / (maxWidth - minWidth)
        return width * percent
    }
}

#Preview {
    BrushSizeSlider(lineWidth: .constant(8))
        .padding()
        .presentationBackground(AppTheme.modalGradient)
}
