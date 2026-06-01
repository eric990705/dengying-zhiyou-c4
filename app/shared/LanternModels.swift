import Foundation
import CoreGraphics

struct LanternDatabase: Codable {
    let lanterns: [Lantern]
    let routes: [LanternRoute]
}

struct Lantern: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let area: String
    let image: String
    let confidenceDemo: Double
    let meaning: String
    let craft: String
    let photoTip: String
    let locationHint: String
    let tags: [String]
}

struct LanternRoute: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let duration: String
    let summary: String
    let lanternIds: [String]
}

struct RecognitionResult: Identifiable, Hashable {
    let id = UUID()
    let lantern: Lantern
    let confidence: Double
    let detectedAt: Date
    let box: DetectionBox
    let engine: DetectionEngine
    let detections: [LanternDetection]
    let sourceImageSize: CGSize
}

struct DetectionBox: Hashable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

enum DetectionEngine: String, Hashable {
    case coreML = "Core ML 模型"
    case visionSaliency = "Vision 目标显著性"
    case colorHeuristic = "彩灯色光规则"
}

struct LanternDetection: Identifiable, Hashable {
    let id = UUID()
    let lantern: Lantern
    let label: String
    let confidence: Double
    let box: DetectionBox
    let engine: DetectionEngine
}

enum DemoData {
    static func load() -> LanternDatabase {
        guard let url = Bundle.main.url(forResource: "lanterns", withExtension: "json") else {
            return fallback
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(LanternDatabase.self, from: data)
        } catch {
            return fallback
        }
    }

    static let fallback = LanternDatabase(
        lanterns: [
            Lantern(
                id: "dinosaur-gate",
                name: "恐龙迎宾灯组",
                category: "恐龙主题",
                area: "迎宾广场",
                image: "zigong_lantern_festival.jpg",
                confidenceDemo: 0.94,
                meaning: "以自贡恐龙文化作为第一视觉记忆点，把城市地质遗产和夜游灯会入口体验连接起来。",
                craft: "大型骨架成型、分区裱糊、内置 LED 轮廓光和局部动态灯效。",
                photoTip: "从入口正中略低角度拍摄，能同时收入拱门、灯组层次和人流尺度。",
                locationHint: "建议作为入园后的第一个识别点，用于触发游客导览路线。",
                tags: ["热门打卡", "亲子研学", "城市名片"]
            )
        ],
        routes: [
            LanternRoute(
                id: "popular",
                name: "热门打卡路线",
                duration: "45 分钟",
                summary: "从入口视觉点开始，串联高辨识度灯组和拍照停留点。",
                lanternIds: ["dinosaur-gate"]
            )
        ]
    )
}
