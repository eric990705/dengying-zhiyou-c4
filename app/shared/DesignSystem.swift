import SwiftUI

enum AppColors {
    static let ink = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let surface = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let card = Color.white
    static let amber = Color(red: 0.95, green: 0.62, blue: 0.16)
    static let red = Color(red: 0.78, green: 0.16, blue: 0.12)
    static let jade = Color(red: 0.10, green: 0.46, blue: 0.38)
    static let blue = Color(red: 0.13, green: 0.30, blue: 0.55)
}

struct Pill: View {
    let text: String
    var color: Color = AppColors.jade

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.10), in: Capsule())
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LanternVisual: View {
    let lantern: Lantern
    var height: CGFloat = 180
    var showsBadge = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(patternOverlay)

            VStack(alignment: .leading, spacing: 8) {
                if showsBadge {
                    HStack(spacing: 8) {
                        Image(systemName: symbolName)
                        Text(lantern.category)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.28), in: Capsule())
                }

                Text(lantern.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }
            .padding(16)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(lantern.name)
    }

    private var gradientColors: [Color] {
        switch lantern.category {
        case "生肖主题", "互动装置":
            return [AppColors.red, AppColors.amber, Color(red: 0.28, green: 0.08, blue: 0.16)]
        case "传统建筑", "传统灯廊", "盐业文化":
            return [AppColors.blue, AppColors.jade, AppColors.amber]
        case "花鸟景观":
            return [Color(red: 0.08, green: 0.35, blue: 0.32), Color(red: 0.85, green: 0.36, blue: 0.42), AppColors.amber]
        default:
            return [Color(red: 0.13, green: 0.08, blue: 0.30), AppColors.red, AppColors.amber]
        }
    }

    private var symbolName: String {
        switch lantern.category {
        case "恐龙主题": return "fossil.shell"
        case "生肖主题": return "hare"
        case "互动装置": return "sparkles"
        case "花鸟景观": return "camera.macro"
        case "传统建筑": return "building.columns"
        case "盐业文化": return "cube"
        default: return "lantern"
        }
    }

    private var patternOverlay: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let stride: CGFloat = max(28, size.width / 10)
                for index in 0..<14 {
                    let x = CGFloat(index) * stride - 20
                    var path = Path()
                    path.addEllipse(in: CGRect(x: x, y: 22 + CGFloat(index % 3) * 34, width: 24, height: 44))
                    context.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1.2)
                }
                var wave = Path()
                wave.move(to: CGPoint(x: 0, y: size.height * 0.70))
                wave.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.62),
                    control1: CGPoint(x: size.width * 0.25, y: size.height * 0.56),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.82)
                )
                context.stroke(wave, with: .color(.white.opacity(0.24)), lineWidth: 2)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

