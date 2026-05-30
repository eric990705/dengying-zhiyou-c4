import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    private let remoteDataURL = URL(string: "https://eric990705.github.io/dengying-zhiyou-c4/api/v1/lanterns.json")

    @Published var database: LanternDatabase
    @Published var selectedLantern: Lantern?
    @Published var recognitionResult: RecognitionResult?
    @Published var isRecognizing = false
    @Published var feedbackMessage = ""
    @Published var feedbackSubmitted = false
    @Published var selectedRoute: LanternRoute?
    @Published var dataSourceMessage = "正在使用本地灯组知识库"
    @Published var isRefreshingRemoteData = false

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

    func refreshFromRemote() async {
        guard let remoteDataURL else {
            dataSourceMessage = "远程数据地址未配置，已使用本地知识库"
            return
        }

        isRefreshingRemoteData = true
        defer { isRefreshingRemoteData = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: remoteDataURL)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                dataSourceMessage = "远程知识库暂不可用，已回退本地数据"
                return
            }

            let remoteDatabase = try JSONDecoder().decode(LanternDatabase.self, from: data)
            database = remoteDatabase
            selectedLantern = remoteDatabase.lanterns.first
            selectedRoute = remoteDatabase.routes.first
            recognitionResult = nil
            dataSourceMessage = "已连接 GitHub Pages 静态知识库"
        } catch {
            dataSourceMessage = "远程知识库暂不可用，已回退本地数据"
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
