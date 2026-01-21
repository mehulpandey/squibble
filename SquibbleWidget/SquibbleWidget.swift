//
//  SquibbleWidget.swift
//  SquibbleWidget
//
//  Displays the most recent doodle received on the home screen
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DoodleEntry: TimelineEntry {
    let date: Date
    let doodleImage: UIImage?
    let senderName: String?
    let senderInitials: String?
    let senderColor: String?
    let doodleID: UUID?
}

// MARK: - Timeline Provider

struct DoodleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoodleEntry {
        DoodleEntry(
            date: Date(),
            doodleImage: nil,
            senderName: "Friend",
            senderInitials: "FR",
            senderColor: "#FF6B6B",
            doodleID: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DoodleEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoodleEntry>) -> Void) {
        let entry = createEntry()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> DoodleEntry {
        let image = WidgetDataManager.getLatestDoodleImage()
        let metadata = WidgetDataManager.getLatestDoodleMetadata()

        return DoodleEntry(
            date: Date(),
            doodleImage: image,
            senderName: metadata?.senderName,
            senderInitials: metadata?.initials,
            senderColor: metadata?.color,
            doodleID: metadata?.doodleID
        )
    }
}

// MARK: - Widget View

struct SquibbleWidgetEntryView: View {
    var entry: DoodleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if let image = entry.doodleImage {
                // Has doodle - show it
                doodleView(image: image)
            } else {
                // No doodle - show empty state
                emptyStateView
            }
        }
        .widgetURL(widgetURL)
    }

    private var widgetURL: URL? {
        if let doodleID = entry.doodleID {
            // Deep link to specific doodle
            return URL(string: "squibble://doodle/\(doodleID.uuidString)")
        } else {
            // Deep link to home/draw screen
            return URL(string: "squibble://draw")
        }
    }

    private func doodleView(image: UIImage) -> some View {
        GeometryReader { geo in
            ZStack {
                // Background color to fill any gaps
                Color.white

                // Doodle image - use .fit to maintain proper alignment
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width, height: geo.size.height)

                // Sender badge (bottom-right)
                if let initials = entry.senderInitials,
                   let colorHex = entry.senderColor {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            senderBadge(initials: initials, colorHex: colorHex)
                                .padding(8)
                        }
                    }
                }
            }
        }
    }

    private func senderBadge(initials: String, colorHex: String) -> some View {
        Text(initials)
            .font(.system(size: badgeSize, weight: .bold))
            .foregroundColor(.white)
            .frame(width: badgeSize * 2, height: badgeSize * 2)
            .background(Color(hex: colorHex))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }

    private var badgeSize: CGFloat {
        switch family {
        case .systemSmall: return 10
        case .systemMedium: return 12
        case .systemLarge: return 14
        case .systemExtraLarge: return 16
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 10
        @unknown default: return 12
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            // Squibble icon placeholder
            Image(systemName: "scribble.variable")
                .font(.system(size: emptyIconSize))
                .foregroundColor(Color(hex: "FF6B54"))

            Text("No doodles yet")
                .font(.system(size: emptyTextSize, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyIconSize: CGFloat {
        switch family {
        case .systemSmall: return 30
        case .systemMedium: return 36
        case .systemLarge: return 44
        case .systemExtraLarge: return 50
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 20
        @unknown default: return 36
        }
    }

    private var emptyTextSize: CGFloat {
        switch family {
        case .systemSmall: return 11
        case .systemMedium: return 13
        case .systemLarge: return 15
        case .systemExtraLarge: return 17
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 10
        @unknown default: return 13
        }
    }
}

// MARK: - Widget Configuration

struct SquibbleWidget: Widget {
    let kind: String = "SquibbleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoodleTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                SquibbleWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                SquibbleWidgetEntryView(entry: entry)
                    .padding(0)
                    .background(Color(UIColor.systemBackground))
            }
        }
        .configurationDisplayName("Squibble")
        .description("See your latest doodle from friends")
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    SquibbleWidget()
} timeline: {
    DoodleEntry(date: .now, doodleImage: nil, senderName: nil, senderInitials: nil, senderColor: nil, doodleID: nil)
}
