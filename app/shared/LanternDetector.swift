import CoreGraphics
import CoreImage
import CoreML
import Foundation
import Vision

enum LanternDetectionError: LocalizedError {
    case unreadableImage
    case emptyDatabase

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "无法读取图片，请换一张更清晰的灯组照片。"
        case .emptyDatabase:
            return "灯组知识库为空，暂时无法匹配识别结果。"
        }
    }
}

final class LanternDetector {
    private let ciContext = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
    private let coreMLRequest: VNCoreMLRequest?

    init() {
        if let modelURL = Bundle.main.url(forResource: "LanternDetector", withExtension: "mlmodelc"),
           let model = try? MLModel(contentsOf: modelURL),
           let visionModel = try? VNCoreMLModel(for: model) {
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .scaleFit
            coreMLRequest = request
        } else {
            coreMLRequest = nil
        }
    }

    func detect(image: PlatformImage, database: LanternDatabase, preferredLantern: Lantern?) async throws -> RecognitionResult {
        guard let cgImage = image.detectionCGImage else {
            throw LanternDetectionError.unreadableImage
        }
        guard !database.lanterns.isEmpty else {
            throw LanternDetectionError.emptyDatabase
        }

        return try await Task.detached(priority: .userInitiated) {
            let size = CGSize(width: cgImage.width, height: cgImage.height)
            let detections = try self.detect(cgImage: cgImage, size: size, database: database, preferredLantern: preferredLantern)
            let rankedDetections = detections.sorted { $0.confidence > $1.confidence }
            let best = rankedDetections[0]

            return RecognitionResult(
                lantern: best.lantern,
                confidence: best.confidence,
                detectedAt: Date(),
                box: best.box,
                engine: best.engine,
                detections: rankedDetections,
                sourceImageSize: size
            )
        }.value
    }

    private func detect(cgImage: CGImage, size: CGSize, database: LanternDatabase, preferredLantern: Lantern?) throws -> [LanternDetection] {
        if let coreMLRequest {
            let coreMLDetections = try runCoreMLDetection(
                request: coreMLRequest,
                cgImage: cgImage,
                database: database,
                preferredLantern: preferredLantern
            )
            if !coreMLDetections.isEmpty {
                return coreMLDetections
            }
        }

        let saliencyDetections = try runSaliencyDetection(
            cgImage: cgImage,
            database: database,
            preferredLantern: preferredLantern
        )
        if !saliencyDetections.isEmpty {
            return saliencyDetections
        }

        return [
            makeHeuristicDetection(
                cgImage: cgImage,
                database: database,
                preferredLantern: preferredLantern,
                box: DetectionBox(x: 0.18, y: 0.16, width: 0.64, height: 0.60),
                confidence: 0.52
            )
        ]
    }

    private func runCoreMLDetection(
        request: VNCoreMLRequest,
        cgImage: CGImage,
        database: LanternDatabase,
        preferredLantern: Lantern?
    ) throws -> [LanternDetection] {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        let objectResults = (request.results as? [VNRecognizedObjectObservation]) ?? []
        let detections = objectResults.compactMap { observation -> LanternDetection? in
            guard let label = observation.labels.first else {
                return nil
            }
            let lantern = matchLantern(label: label.identifier, database: database) ?? preferredLantern ?? database.lanterns[0]
            return LanternDetection(
                lantern: lantern,
                label: label.identifier,
                confidence: Double(label.confidence),
                box: DetectionBox(visionBoundingBox: observation.boundingBox),
                engine: .coreML
            )
        }

        return Array(detections.sorted { $0.confidence > $1.confidence }.prefix(5))
    }

    private func runSaliencyDetection(
        cgImage: CGImage,
        database: LanternDatabase,
        preferredLantern: Lantern?
    ) throws -> [LanternDetection] {
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        let salientObjects = observations
            .flatMap { $0.salientObjects ?? [] }
            .sorted { $0.confidence > $1.confidence }

        let objects = salientObjects.isEmpty ? [fallbackRectangle()] : Array(salientObjects.prefix(4))
        return objects.enumerated().map { index, object in
            let box = DetectionBox(visionBoundingBox: object.boundingBox).clamped()
            let lantern = preferredLantern ?? inferLantern(cgImage: cgImage, box: box, database: database, offset: index)
            let confidence = max(0.50, min(0.94, Double(object.confidence)))
            return LanternDetection(
                lantern: lantern,
                label: "彩灯主体",
                confidence: confidence,
                box: box,
                engine: .visionSaliency
            )
        }
    }

    private func fallbackRectangle() -> VNRectangleObservation {
        VNRectangleObservation(boundingBox: CGRect(x: 0.18, y: 0.18, width: 0.64, height: 0.58))
    }

    private func makeHeuristicDetection(
        cgImage: CGImage,
        database: LanternDatabase,
        preferredLantern: Lantern?,
        box: DetectionBox,
        confidence: Double
    ) -> LanternDetection {
        LanternDetection(
            lantern: preferredLantern ?? inferLantern(cgImage: cgImage, box: box, database: database, offset: 0),
            label: "高饱和彩灯区域",
            confidence: confidence,
            box: box,
            engine: .colorHeuristic
        )
    }

    private func inferLantern(cgImage: CGImage, box: DetectionBox, database: LanternDatabase, offset: Int) -> Lantern {
        let feature = colorFeature(cgImage: cgImage, box: box)
        let ranked: [(index: Int, lantern: Lantern, score: Double)] = database.lanterns.enumerated().map { index, lantern in
            let text = "\(lantern.name) \(lantern.category) \(lantern.tags.joined(separator: " "))"
            var score = Double(lantern.confidenceDemo) * 0.18

            if feature.warmRatio > 0.42 {
                score += text.contains("龙") || text.contains("生肖") || text.contains("恐龙") || text.contains("凤凰") ? 0.42 : 0.16
            }
            if feature.coolRatio > 0.28 {
                score += text.contains("鲸") || text.contains("水景") || text.contains("建筑") || text.contains("盐业") ? 0.38 : 0.10
            }
            if feature.greenRatio > 0.20 {
                score += text.contains("荷") || text.contains("花") || text.contains("互动") ? 0.30 : 0.08
            }
            if feature.saturation > 0.48 {
                score += text.contains("热门") || text.contains("打卡") || text.contains("华彩") ? 0.16 : 0.06
            }

            return (index: index, lantern: lantern, score: score)
        }

        return ranked.sorted { left, right in
            if abs(left.score - right.score) > 0.0001 {
                return left.score > right.score
            }
            return ((left.index + offset) % database.lanterns.count) < ((right.index + offset) % database.lanterns.count)
        }[0].lantern
    }

    private func matchLantern(label: String, database: LanternDatabase) -> Lantern? {
        let normalizedLabel = normalize(label)
        return database.lanterns.first { lantern in
            normalize(lantern.id) == normalizedLabel ||
            normalize(lantern.name).contains(normalizedLabel) ||
            normalize(lantern.category).contains(normalizedLabel) ||
            lantern.tags.contains { normalize($0).contains(normalizedLabel) }
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }

    private func colorFeature(cgImage: CGImage, box: DetectionBox) -> ColorFeature {
        let width = 24
        let height = 24
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return ColorFeature()
        }

        let cropRect = box.cgImageCropRect(imageWidth: cgImage.width, imageHeight: cgImage.height)
        guard let crop = cgImage.cropping(to: cropRect) else {
            return ColorFeature()
        }

        context.interpolationQuality = .low
        context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))

        var warm = 0
        var cool = 0
        var green = 0
        var saturated = 0
        let total = width * height

        for index in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[index]) / 255.0
            let greenValue = Double(pixels[index + 1]) / 255.0
            let blue = Double(pixels[index + 2]) / 255.0
            let maxChannel = max(red, greenValue, blue)
            let minChannel = min(red, greenValue, blue)
            let saturation = maxChannel == 0 ? 0 : (maxChannel - minChannel) / maxChannel

            if red > 0.48 && red > greenValue * 1.12 && red > blue * 1.08 {
                warm += 1
            }
            if blue > 0.38 && blue > red * 0.92 {
                cool += 1
            }
            if greenValue > 0.38 && greenValue > red * 0.72 && greenValue > blue * 0.72 {
                green += 1
            }
            if saturation > 0.34 && maxChannel > 0.24 {
                saturated += 1
            }
        }

        return ColorFeature(
            warmRatio: Double(warm) / Double(total),
            coolRatio: Double(cool) / Double(total),
            greenRatio: Double(green) / Double(total),
            saturation: Double(saturated) / Double(total)
        )
    }
}

private struct ColorFeature {
    var warmRatio: Double = 0
    var coolRatio: Double = 0
    var greenRatio: Double = 0
    var saturation: Double = 0
}

extension DetectionBox {
    init(visionBoundingBox: CGRect) {
        self.init(
            x: visionBoundingBox.minX,
            y: 1 - visionBoundingBox.maxY,
            width: visionBoundingBox.width,
            height: visionBoundingBox.height
        )
    }

    func clamped() -> DetectionBox {
        let clampedX = min(max(x, 0), 1)
        let clampedY = min(max(y, 0), 1)
        let clampedWidth = min(max(width, 0.04), 1 - clampedX)
        let clampedHeight = min(max(height, 0.04), 1 - clampedY)
        return DetectionBox(x: clampedX, y: clampedY, width: clampedWidth, height: clampedHeight)
    }

    func cgImageCropRect(imageWidth: Int, imageHeight: Int) -> CGRect {
        let cropX = CGFloat(x) * CGFloat(imageWidth)
        let cropY = CGFloat(y) * CGFloat(imageHeight)
        let cropWidth = CGFloat(width) * CGFloat(imageWidth)
        let cropHeight = CGFloat(height) * CGFloat(imageHeight)
        return CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight).integral
    }
}
