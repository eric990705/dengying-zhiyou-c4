import SwiftUI

struct RecognitionView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle("拍照识别", subtitle: "原型阶段先用稳定演示流，后续接入 YOLO/CoreML")

                    detectionPreview
                    actionPanel

                    if let result = viewModel.recognitionResult {
                        RecognitionResultCard(result: result)
                        LanternDetailCard(lantern: result.lantern)
                        feedbackPanel
                    } else {
                        emptyResult
                    }
                }
                .padding()
            }
            .background(AppColors.surface.ignoresSafeArea())
            .navigationTitle("AI识别")
        }
    }

    private var currentLantern: Lantern {
        viewModel.selectedLantern ?? viewModel.database.lanterns[0]
    }

    private var detectionPreview: some View {
        ZStack {
            LanternVisual(lantern: currentLantern, height: 300)
                .overlay {
                    if viewModel.isRecognizing {
                        ProgressView("正在识别灯组")
                            .font(.headline)
                            .padding(18)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    if viewModel.recognitionResult != nil {
                        GeometryReader { proxy in
                            let box = viewModel.recognitionResult?.box ?? DetectionBox(x: 0.16, y: 0.18, width: 0.68, height: 0.52)
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppColors.amber, lineWidth: 3)
                                .background(AppColors.amber.opacity(0.08))
                                .frame(width: proxy.size.width * box.width, height: proxy.size.height * box.height)
                                .position(
                                    x: proxy.size.width * (box.x + box.width / 2),
                                    y: proxy.size.height * (box.y + box.height / 2)
                                )
                        }
                    }
                }
        }
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择一个样板灯组运行识别")
                .font(.headline)

            Picker("灯组", selection: Binding(
                get: { viewModel.selectedLantern?.id ?? currentLantern.id },
                set: { id in
                    viewModel.selectedLantern = viewModel.database.lanterns.first(where: { $0.id == id })
                }
            )) {
                ForEach(viewModel.database.lanterns) { lantern in
                    Text(lantern.name).tag(lantern.id)
                }
            }
            #if os(macOS)
            .pickerStyle(.menu)
            #else
            .pickerStyle(.navigationLink)
            #endif

            HStack(spacing: 12) {
                Button {
                    viewModel.runDemoRecognition(preferred: currentLantern)
                } label: {
                    Label("运行演示识别", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.red)

                Button {
                    viewModel.recognitionResult = nil
                } label: {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyResult: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("等待识别结果", systemImage: "viewfinder")
                .font(.headline)
            Text("正式 iOS 版本将接入相机、相册和后端检测接口。当前演示用于验证完整游客旅程。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var feedbackPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("识别反馈")
                .font(.headline)
            HStack(spacing: 12) {
                Button {
                    viewModel.submitFeedback(isAccurate: true)
                } label: {
                    Label("准确", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.jade)

                Button {
                    viewModel.submitFeedback(isAccurate: false)
                } label: {
                    Label("需要纠错", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if viewModel.feedbackSubmitted {
                Text(viewModel.feedbackMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.jade)
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RecognitionResultCard: View {
    let result: RecognitionResult

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(AppColors.jade)
            VStack(alignment: .leading, spacing: 8) {
                Text(result.lantern.name)
                    .font(.title3.weight(.bold))
                HStack {
                    Pill(text: "置信度 \(Int(result.confidence * 100))%", color: AppColors.red)
                    Pill(text: result.lantern.area, color: AppColors.blue)
                }
                Text("识别后自动匹配知识卡片、展区位置和推荐路线。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

