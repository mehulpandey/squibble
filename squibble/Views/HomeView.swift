//
//  HomeView.swift
//  squibble
//
//  Main home screen with drawing canvas and send button
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var doodleManager: DoodleManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var userManager: UserManager

    @ObservedObject var drawingState: DrawingState
    @StateObject private var favoriteColorsManager = FavoriteColorsManager.shared

    @State private var showColorPicker = false
    @State private var showBrushSize = false
    @State private var showSendSheet = false
    @State private var showAddFriends = false
    @State private var showUpgrade = false
    @State private var showMoreOptions = false
    @State private var selectedFavoriteIndex: Int = 0

    // Pending navigation after sheet dismissal
    @State private var pendingNavigation: PendingNavigation? = nil

    private enum PendingNavigation {
        case addFriends
        case upgrade
    }

    // Consistent spacing value used throughout
    private let elementSpacing: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 20
            let containerWidth = geometry.size.width - (horizontalPadding * 2)

            VStack(spacing: 0) {
                // Header
                headerBar

                Spacer()

                // Canvas container (glass-morphism card) - centered vertically
                canvasContainerView(containerWidth: containerWidth)
                    .padding(.horizontal, horizontalPadding)

                Spacer()

                // Space for tab bar
                Spacer().frame(height: 100)
            }
            .frame(width: geometry.size.width)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showColorPicker) {
            ExpandedColorPickerView(
                selectedColor: $drawingState.selectedColor,
                favoriteIndex: selectedFavoriteIndex,
                onColorSelected: { color, index in
                    favoriteColorsManager.updateFavorite(at: index, with: color)
                    drawingState.selectedColor = color
                }
            )
            .presentationDetents([.height(450)])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.modalGradient)
        }
        .sheet(isPresented: $showBrushSize) {
            BrushSizeSlider(lineWidth: drawingState.selectedTool == .eraser
                ? $drawingState.eraserLineWidth
                : $drawingState.penLineWidth)
                .presentationDetents([.height(180)])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppTheme.modalGradient)
        }
        .sheet(isPresented: $showSendSheet, onDismiss: handleSheetDismiss) {
            SendSheet(
                drawingState: drawingState,
                isPresented: $showSendSheet,
                onAddFriends: {
                    pendingNavigation = .addFriends
                    showSendSheet = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(AppTheme.modalGradient)
        }
        .sheet(isPresented: $showAddFriends) {
            AddFriendsView()
        }
        .sheet(isPresented: $showMoreOptions, onDismiss: handleSheetDismiss) {
            MoreOptionsSheet(
                drawingState: drawingState,
                onShowUpgrade: {
                    pendingNavigation = .upgrade
                    showMoreOptions = false
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.modalGradient)
        }
        .fullScreenCover(isPresented: $showUpgrade) {
            UpgradeView()
        }
        .onAppear {
            // Set initial drawing color to first favorite
            if !favoriteColorsManager.favoriteColors.isEmpty {
                drawingState.selectedColor = favoriteColorsManager.favoriteColors[0]
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            Text("Home")
                .font(.custom("Avenir-Heavy", size: 32))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            // Level Up / Premium button
            Button(action: { showUpgrade = true }) {
                HStack(spacing: 6) {
                    Image(systemName: userManager.currentUser?.isPremium == true ? "crown.fill" : "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text(userManager.currentUser?.isPremium == true ? "Premium" : "Level Up")
                        .font(.custom("Avenir-Heavy", size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.primaryGlow, radius: 16, x: 0, y: 4)
            }

            // Add Friends button with pending request badge
            Button(action: { showAddFriends = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.primaryStart)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.glassBackgroundStrong)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.glassBorder, lineWidth: 1)
                        )
                        .clipShape(Circle())

                    // Pending request badge
                    if friendManager.pendingRequestCount > 0 {
                        Text("\(friendManager.pendingRequestCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(AppTheme.primaryEnd)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0)
    }

    // MARK: - Canvas Container

    private func canvasContainerView(containerWidth: CGFloat) -> some View {
        let canvasSize = containerWidth - 32 // 16px padding on each side

        return VStack(spacing: 0) {
            // TOP: Drawing toolbar
            drawingToolbar
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Divider
            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)
                .padding(.horizontal, 16)

            // MIDDLE: Drawing area (1:1 aspect ratio)
            ZStack {
                // Drawing area background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.canvasGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.canvasBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                // Actual drawing canvas
                DrawingCanvas(
                    state: drawingState,
                    canvasSize: CGSize(width: canvasSize, height: canvasSize)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Empty state hint (adapts to background color)
                if drawingState.isEmpty {
                    let hintColor = emptyStateHintColor(for: drawingState.canvasBackgroundColor)
                    VStack(spacing: 10) {
                        Image(systemName: "scribble.variable")
                            .font(.system(size: 36))
                            .foregroundColor(hintColor)
                        Text("Start drawing!")
                            .font(.custom("Avenir-Medium", size: 15))
                            .foregroundColor(hintColor)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(width: canvasSize, height: canvasSize)
            .padding(.vertical, 16)

            // Divider
            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)
                .padding(.horizontal, 16)

            // BOTTOM: Canvas controls (undo/redo, send, clear/more)
            canvasControls
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .glassContainer(cornerRadius: 24)
    }

    // MARK: - Drawing Toolbar

    private var drawingToolbar: some View {
        HStack(spacing: 8) {
            // Pen tool
            toolButton(
                icon: "pencil.tip",
                isSelected: drawingState.selectedTool == .pen,
                action: {
                    if drawingState.selectedTool == .pen {
                        showBrushSize = true
                    } else {
                        drawingState.selectedTool = .pen
                    }
                }
            )

            // Eraser tool
            toolButton(
                icon: "eraser",
                isSelected: drawingState.selectedTool == .eraser,
                action: {
                    if drawingState.selectedTool == .eraser {
                        showBrushSize = true
                    } else {
                        drawingState.selectedTool = .eraser
                    }
                }
            )

            // Divider
            Rectangle()
                .fill(AppTheme.divider)
                .frame(width: 1, height: 28)
                .padding(.horizontal, 6)

            // 5 Favorite color circles
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    favoriteColorButton(index: index)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func toolButton(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 40, height: 40)
                        .shadow(color: AppTheme.primaryGlow, radius: 12, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(AppTheme.buttonInactiveBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.buttonInactiveBorder, lineWidth: 1)
                        )
                }

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.buttonInactiveText)

                // Size indicator badge when selected (shows user can tap for size)
                if isSelected {
                    Circle()
                        .fill(AppTheme.backgroundBottom)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .overlay(
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 14, y: -14)
                }
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func favoriteColorButton(index: Int) -> some View {
        let color = favoriteColorsManager.favoriteColors.indices.contains(index)
            ? favoriteColorsManager.favoriteColors[index]
            : Color.gray
        let isSelected = drawingState.selectedColor.toHex() == color.toHex() && selectedFavoriteIndex == index

        Button(action: {
            if isSelected {
                // Already selected - open color picker to change
                selectedFavoriteIndex = index
                showColorPicker = true
            } else {
                // Select this color for drawing
                selectedFavoriteIndex = index
                drawingState.selectedColor = color
            }
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .shadow(color: color.opacity(0.5), radius: isSelected ? 8 : 0, x: 0, y: 0)

                // Selection ring (white border with glow)
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2.5)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)

                    // Edit indicator - dark background with white icon for visibility
                    Circle()
                        .fill(AppTheme.backgroundBottom)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Canvas Controls

    private var canvasControls: some View {
        HStack(spacing: 12) {
            // Left side: Undo/Redo
            HStack(spacing: 8) {
                canvasControlButton(
                    icon: "arrow.uturn.backward",
                    enabled: drawingState.canUndo
                ) {
                    drawingState.undo()
                }

                canvasControlButton(
                    icon: "arrow.uturn.forward",
                    enabled: drawingState.canRedo
                ) {
                    drawingState.redo()
                }
            }

            Spacer()

            // Center: Large Send button
            Button(action: { showSendSheet = true }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        drawingState.isEmpty
                            ? AnyShapeStyle(AppTheme.buttonInactiveBackground)
                            : AnyShapeStyle(AppTheme.primaryGradient)
                    )
                    .clipShape(Circle())
                    .shadow(
                        color: drawingState.isEmpty ? .clear : AppTheme.primaryGlow,
                        radius: 16,
                        x: 0,
                        y: 4
                    )
            }
            .disabled(drawingState.isEmpty)
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // Right side: Trash/More Options
            HStack(spacing: 8) {
                canvasControlButton(
                    icon: "trash",
                    enabled: !drawingState.paths.isEmpty || drawingState.currentPath != nil
                ) {
                    drawingState.clearDrawingOnly()
                }

                Button(action: { showMoreOptions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryStart)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.buttonInactiveBackground)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.primaryStart.opacity(0.5), lineWidth: 1.5)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func canvasControlButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(enabled ? AppTheme.textPrimary : AppTheme.textInactive)
                .frame(width: 40, height: 40)
                .background(AppTheme.buttonInactiveBackground)
                .overlay(
                    Circle()
                        .stroke(AppTheme.buttonInactiveBorder, lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .disabled(!enabled)
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Sheet Dismissal Handler

    private func handleSheetDismiss() {
        guard let navigation = pendingNavigation else { return }
        pendingNavigation = nil

        // Small delay to ensure previous sheet is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch navigation {
            case .addFriends:
                showAddFriends = true
            case .upgrade:
                showUpgrade = true
            }
        }
    }

    /// Returns an appropriate hint color based on canvas background brightness
    private func emptyStateHintColor(for bgColor: Color) -> Color {
        let uiColor = UIColor(bgColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Perceived brightness (ITU-R BT.601)
        let brightness = r * 0.299 + g * 0.587 + b * 0.114
        return brightness > 0.5
            ? Color.black.opacity(0.2)
            : Color.white.opacity(0.25)
    }
}

#Preview {
    HomeView(drawingState: DrawingState())
        .environmentObject(DoodleManager())
        .environmentObject(AuthManager())
        .environmentObject(FriendManager())
        .environmentObject(NavigationManager())
}
