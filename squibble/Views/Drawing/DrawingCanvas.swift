//
//  DrawingCanvas.swift
//  squibble
//
//  Core drawing canvas with touch support
//

import SwiftUI
import Combine

// MARK: - Drawing Models

struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: CGFloat = 4, isEraser: Bool = false) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.isEraser = isEraser
    }
}

// MARK: - Drawing State

@MainActor
class DrawingState: ObservableObject {
    @Published var paths: [DrawingPath] = []
    @Published var currentPath: DrawingPath?
    @Published var undoStack: [DrawingPath] = []

    @Published var selectedColor: Color = Color(hex: "2D2D2D")
    @Published var selectedTool: DrawingTool = .pen
    @Published var lineWidth: CGFloat = 8
    @Published var canvasBackgroundColor: Color = .white
    @Published var backgroundImage: UIImage?

    // Image adjustment properties
    @Published var imageScale: CGFloat = 1.0
    @Published var imageOffset: CGSize = .zero

    // Track the canvas size used during drawing for proper export scaling
    var currentCanvasSize: CGSize = .zero

    var canUndo: Bool { !paths.isEmpty }
    var canRedo: Bool { !undoStack.isEmpty }
    var isEmpty: Bool { paths.isEmpty && currentPath == nil && backgroundImage == nil }

    func startPath(at point: CGPoint) {
        let isEraser = selectedTool == .eraser
        currentPath = DrawingPath(
            points: [point],
            color: isEraser ? .white : selectedColor,
            lineWidth: isEraser ? lineWidth * 2.5 : lineWidth,
            isEraser: isEraser
        )
    }

    func addPoint(_ point: CGPoint) {
        currentPath?.points.append(point)
    }

    func endPath() {
        if let path = currentPath, path.points.count > 1 {
            paths.append(path)
            undoStack.removeAll() // Clear redo stack on new action
        }
        currentPath = nil
    }

    func undo() {
        guard let lastPath = paths.popLast() else { return }
        undoStack.append(lastPath)
    }

    func redo() {
        guard let redoPath = undoStack.popLast() else { return }
        paths.append(redoPath)
    }

    func clear() {
        // Clear drawings only, preserve background color
        paths.removeAll()
        undoStack.removeAll()
        currentPath = nil
        // Reset image if present
        backgroundImage = nil
        imageScale = 1.0
        imageOffset = .zero
    }

    func clearAll() {
        // Clear everything including background color (used for full reset after sending)
        paths.removeAll()
        undoStack.removeAll()
        currentPath = nil
        backgroundImage = nil
        canvasBackgroundColor = .white
        imageScale = 1.0
        imageOffset = .zero
    }

    func clearDrawingOnly() {
        paths.removeAll()
        undoStack.removeAll()
        currentPath = nil
    }
}

enum DrawingTool {
    case pen
    case eraser
}

// MARK: - Drawing Canvas View

struct DrawingCanvas: View {
    @ObservedObject var state: DrawingState
    let canvasSize: CGSize

    // Check if background image is present (for showing hint and enabling 2-finger gestures)
    private var hasBackgroundImage: Bool {
        state.backgroundImage != nil
    }

    var body: some View {
        ZStack {
            // Background color
            state.canvasBackgroundColor
                .onAppear {
                    // Store the canvas size for proper export scaling
                    state.currentCanvasSize = canvasSize
                }

            // Background image if present
            if let bgImage = state.backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(state.imageScale)
                    .offset(state.imageOffset)
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .clipped()
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.imageOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.imageScale)
            }

            // Drawing canvas
            Canvas { context, size in
                // Draw all completed paths
                for path in state.paths {
                    drawPath(path, in: &context)
                }

                // Draw current path
                if let currentPath = state.currentPath {
                    drawPath(currentPath, in: &context)
                }
            }

            // Image adjustment hint overlay (only show when image present and no drawings yet)
            if hasBackgroundImage && state.paths.isEmpty {
                VStack {
                    Spacer()
                    Text("Pinch to zoom, two fingers to move")
                        .font(.custom("Avenir-Medium", size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                }
            }

            // Two-finger gesture overlay for image adjustment (always active when image present)
            if hasBackgroundImage {
                TwoFingerGestureView(
                    state: state,
                    canvasSize: canvasSize
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .contentShape(Rectangle())
        .gesture(drawingGesture)
    }

    // Drawing gesture (1 finger) - always active
    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location
                if state.currentPath == nil {
                    state.startPath(at: point)
                } else {
                    state.addPoint(point)
                }
            }
            .onEnded { _ in
                state.endPath()
            }
    }

    private func drawPath(_ path: DrawingPath, in context: inout GraphicsContext) {
        guard path.points.count > 1 else { return }

        var swiftUIPath = Path()
        swiftUIPath.move(to: path.points[0])

        // Use quadratic curves for smooth lines
        for i in 1..<path.points.count {
            let current = path.points[i]
            let previous = path.points[i - 1]
            let mid = CGPoint(
                x: (current.x + previous.x) / 2,
                y: (current.y + previous.y) / 2
            )

            if i == 1 {
                swiftUIPath.addLine(to: mid)
            } else {
                swiftUIPath.addQuadCurve(to: mid, control: previous)
            }
        }

        // Add final point
        if let last = path.points.last {
            swiftUIPath.addLine(to: last)
        }

        if path.isEraser {
            context.blendMode = .destinationOut
        } else {
            context.blendMode = .normal
        }

        context.stroke(
            swiftUIPath,
            with: .color(path.color),
            style: StrokeStyle(
                lineWidth: path.lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}

// MARK: - Canvas Export

extension DrawingState {
    @MainActor
    func exportToPNG(size: CGSize, originalCanvasSize: CGSize? = nil) -> Data? {
        let pathsToRender = self.paths
        let bgColor = self.canvasBackgroundColor
        let bgImage = self.backgroundImage
        let imgScale = self.imageScale
        let imgOffset = self.imageOffset

        // Calculate scale factor if we need to normalize coordinates
        let scaleX: CGFloat
        let scaleY: CGFloat
        let lineWidthScale: CGFloat
        if let originalSize = originalCanvasSize, originalSize.width > 0, originalSize.height > 0 {
            scaleX = size.width / originalSize.width
            scaleY = size.height / originalSize.height
            lineWidthScale = min(scaleX, scaleY)
        } else {
            scaleX = 1.0
            scaleY = 1.0
            lineWidthScale = 1.0
        }

        // Scale the image offset proportionally
        let scaledImgOffset = CGSize(
            width: imgOffset.width * scaleX,
            height: imgOffset.height * scaleY
        )

        let renderer = ImageRenderer(content:
            ZStack {
                // Background color
                bgColor

                // Background image if present (with scale and offset)
                if let bgImage = bgImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(imgScale)
                        .offset(scaledImgOffset)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                }

                // Drawing paths
                Canvas { context, _ in
                    for path in pathsToRender {
                        guard path.points.count > 1 else { continue }

                        // Scale path points to export size
                        let scaledPoints = path.points.map { point in
                            CGPoint(x: point.x * scaleX, y: point.y * scaleY)
                        }

                        var swiftUIPath = Path()
                        swiftUIPath.move(to: scaledPoints[0])

                        for i in 1..<scaledPoints.count {
                            let current = scaledPoints[i]
                            let previous = scaledPoints[i - 1]
                            let mid = CGPoint(
                                x: (current.x + previous.x) / 2,
                                y: (current.y + previous.y) / 2
                            )

                            if i == 1 {
                                swiftUIPath.addLine(to: mid)
                            } else {
                                swiftUIPath.addQuadCurve(to: mid, control: previous)
                            }
                        }

                        if let last = scaledPoints.last {
                            swiftUIPath.addLine(to: last)
                        }

                        if path.isEraser {
                            context.blendMode = .destinationOut
                        } else {
                            context.blendMode = .normal
                        }

                        context.stroke(
                            swiftUIPath,
                            with: .color(path.color),
                            style: StrokeStyle(
                                lineWidth: path.lineWidth * lineWidthScale,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        )

        renderer.scale = 2.0 // Retina

        guard let uiImage = renderer.uiImage else { return nil }
        return uiImage.pngData()
    }
}

// MARK: - Two-Finger Gesture View (UIKit-based for proper 2-finger detection)

struct TwoFingerGestureView: UIViewRepresentable {
    @ObservedObject var state: DrawingState
    let canvasSize: CGSize

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state, canvasSize: canvasSize)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // Pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinchGesture)

        // Pan gesture for drag (requires 2 fingers)
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        view.addGestureRecognizer(panGesture)

        // Allow both gestures simultaneously
        pinchGesture.delegate = context.coordinator
        panGesture.delegate = context.coordinator

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.state = state
        context.coordinator.canvasSize = canvasSize
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var state: DrawingState
        var canvasSize: CGSize

        private var lastScale: CGFloat = 1.0
        private var lastOffset: CGSize = .zero

        init(state: DrawingState, canvasSize: CGSize) {
            self.state = state
            self.canvasSize = canvasSize
            super.init()
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                lastScale = state.imageScale
                // Cancel any in-progress single-finger drawing that might have started
                Task { @MainActor in
                    state.currentPath = nil
                }
            case .changed:
                let newScale = lastScale * gesture.scale
                Task { @MainActor in
                    state.imageScale = min(max(newScale, 1.0), 3.0)
                }
            case .ended, .cancelled:
                lastScale = state.imageScale
                clampImageBounds()
            default:
                break
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)

            switch gesture.state {
            case .began:
                lastOffset = state.imageOffset
                // Cancel any in-progress single-finger drawing that might have started
                Task { @MainActor in
                    state.currentPath = nil
                }
            case .changed:
                Task { @MainActor in
                    state.imageOffset = CGSize(
                        width: lastOffset.width + translation.x,
                        height: lastOffset.height + translation.y
                    )
                }
            case .ended, .cancelled:
                lastOffset = state.imageOffset
                clampImageBounds()
            default:
                break
            }
        }

        private func clampImageBounds() {
            guard let bgImage = state.backgroundImage else { return }

            let imageAspect = bgImage.size.width / bgImage.size.height
            let canvasAspect = canvasSize.width / canvasSize.height

            let scaledWidth: CGFloat
            let scaledHeight: CGFloat

            if imageAspect > canvasAspect {
                scaledHeight = canvasSize.height * state.imageScale
                scaledWidth = scaledHeight * imageAspect
            } else {
                scaledWidth = canvasSize.width * state.imageScale
                scaledHeight = scaledWidth / imageAspect
            }

            let maxOffsetX = max(0, (scaledWidth - canvasSize.width) / 2)
            let maxOffsetY = max(0, (scaledHeight - canvasSize.height) / 2)

            let clampedOffset = CGSize(
                width: min(max(state.imageOffset.width, -maxOffsetX), maxOffsetX),
                height: min(max(state.imageOffset.height, -maxOffsetY), maxOffsetY)
            )

            Task { @MainActor in
                state.imageOffset = clampedOffset
            }
            lastOffset = clampedOffset
        }

        // Allow simultaneous gesture recognition
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

#Preview {
    DrawingCanvas(state: DrawingState(), canvasSize: CGSize(width: 350, height: 400))
        .clipShape(RoundedRectangle(cornerRadius: 24))
}
