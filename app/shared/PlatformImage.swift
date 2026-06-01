import CoreGraphics
import SwiftUI

#if os(iOS)
import UIKit

typealias PlatformImage = UIImage

extension PlatformImage {
    var detectionCGImage: CGImage? {
        cgImage
    }

    var detectionSize: CGSize {
        size
    }

    static func sampleLanternImage(for lantern: Lantern) -> PlatformImage {
        let size = CGSize(width: 1200, height: 820)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            LanternSampleRenderer.draw(lantern: lantern, in: CGRect(origin: .zero, size: size), context: context.cgContext)
        }
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        self.init(uiImage: platformImage)
    }
}
#elseif os(macOS)
import AppKit

typealias PlatformImage = NSImage

extension PlatformImage {
    var detectionCGImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    var detectionSize: CGSize {
        size
    }

    static func sampleLanternImage(for lantern: Lantern) -> PlatformImage {
        let size = CGSize(width: 1200, height: 820)
        let image = NSImage(size: size)
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            LanternSampleRenderer.draw(lantern: lantern, in: CGRect(origin: .zero, size: size), context: context)
        }
        image.unlockFocus()
        return image
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        self.init(nsImage: platformImage)
    }
}
#endif

enum LanternSampleRenderer {
    static func draw(lantern: Lantern, in rect: CGRect, context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }

        let background = CGColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1)
        context.setFillColor(background)
        context.fill(rect)

        drawGlow(center: CGPoint(x: rect.midX, y: rect.midY), radius: 360, color: CGColor(red: 0.95, green: 0.25, blue: 0.14, alpha: 0.55), context: context)
        drawGlow(center: CGPoint(x: rect.midX + 230, y: rect.midY - 80), radius: 260, color: CGColor(red: 1.0, green: 0.68, blue: 0.12, alpha: 0.42), context: context)
        drawGlow(center: CGPoint(x: rect.midX - 260, y: rect.midY + 80), radius: 220, color: CGColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 0.30), context: context)

        let bodyRect = CGRect(x: rect.midX - 250, y: rect.midY - 180, width: 500, height: 320)
        context.setFillColor(CGColor(red: 0.88, green: 0.13, blue: 0.10, alpha: 0.96))
        context.fillEllipse(in: bodyRect)
        context.setStrokeColor(CGColor(red: 1.0, green: 0.72, blue: 0.22, alpha: 1))
        context.setLineWidth(12)
        context.strokeEllipse(in: bodyRect.insetBy(dx: 8, dy: 8))

        for offset in stride(from: -180, through: 180, by: 90) {
            let rib = CGRect(x: bodyRect.midX + CGFloat(offset) - 18, y: bodyRect.minY + 18, width: 36, height: bodyRect.height - 36)
            context.setStrokeColor(CGColor(red: 1.0, green: 0.55, blue: 0.18, alpha: 0.82))
            context.setLineWidth(5)
            context.strokeEllipse(in: rib)
        }

        let labelRect = CGRect(x: bodyRect.midX - 170, y: bodyRect.midY - 36, width: 340, height: 72)
        context.setFillColor(CGColor(red: 1, green: 0.82, blue: 0.32, alpha: 0.92))
        context.fill(labelRect)

        let smallLights = [
            CGPoint(x: rect.midX - 420, y: rect.midY + 220),
            CGPoint(x: rect.midX + 420, y: rect.midY + 180),
            CGPoint(x: rect.midX - 360, y: rect.midY - 250),
            CGPoint(x: rect.midX + 340, y: rect.midY - 240)
        ]
        for point in smallLights {
            drawGlow(center: point, radius: 80, color: CGColor(red: 1.0, green: 0.55, blue: 0.16, alpha: 0.42), context: context)
            context.setFillColor(CGColor(red: 0.96, green: 0.28, blue: 0.12, alpha: 0.92))
            context.fillEllipse(in: CGRect(x: point.x - 36, y: point.y - 52, width: 72, height: 104))
        }
    }

    private static func drawGlow(center: CGPoint, radius: CGFloat, color: CGColor, context: CGContext) {
        let clear = color.copy(alpha: 0) ?? color
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [color, clear] as CFArray, locations: [0, 1]) else {
            return
        }
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
    }
}
