import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var database: LanternDatabase
    @Published var selectedLantern: Lantern?
    @Published var recognitionResult: RecognitionResult?
    @Published var isRecognizing = false
    @Published var feedbackMessage = ""
    @Published var feedbackSubmitted = false
    @Published var selectedRoute: LanternRoute?

    init(database: LanternDatabase = DemoData.load()) {
        self.database = database
        self.selectedLantern = database.lanterns.first
        self.selectedRoute = database.routes.first
    }

    var hotLanterns: [Lantern] {
        Array(database.lanterns.prefix(6))
    }

    func lanterns(for route: LanternRoute) -> [Lantern] {
        route.lanternIds.compactMap { id in
            database.lanterns.first(where: { $0.id == id })
        }
    }

    func runDemoRecognition(preferred lantern: Lantern? = nil) {
        isRecognizing = true
        feedbackSubmitted = false
        feedbackMessage = ""

        let candidate = lantern ?? selectedLantern ?? database.lanterns.first
        guard let candidate else {
            isRecognizing = false
            return
        }

        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            recognitionResult = RecognitionResult(
                lantern: candidate,
                confidence: candidate.confidenceDemo,
                detectedAt: Date(),
                box: DetectionBox(x: 0.16, y: 0.18, width: 0.68, height: 0.52)
            )
            selectedLantern = candidate
            isRecognizing = false
        }
    }

    func submitFeedback(isAccurate: Bool) {
        feedbackSubmitted = true
        feedbackMessage = isAccurate ? "已记录为识别准确，感谢反馈。" : "已加入待复核样本，后台会用于模型迭代。"
    }
}

